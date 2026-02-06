#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>

#define SOCKET_PATH "os.socket"
#define MAX_FILES 10
#define FILE_MAX 128

// Simple struct to remember which files we have touched
typedef struct {
    char name[FILE_MAX + 2]; // Store "/filename"
    int used;
} shm_tracker_t;

// Basic error helper
static void die(const char *msg) {
    perror(msg);
    exit(EXIT_FAILURE);
}

// Helper: receive string
static int recv_string(int sock, char *buf, size_t size) {
    ssize_t n = recv(sock, buf, size - 1, 0);
    if (n <= 0) return -1;
    buf[n] = '\0';
    return n;
}

// Helper: Send SHM Name + FD (Boilerplate required by assignment)
static void send_shm_and_fd(int sock, char *shm_name, int fd) {
    struct iovec msg_io = { .iov_base = shm_name, .iov_len = strlen(shm_name) + 1 };
    struct msghdr msg = { .msg_iov = &msg_io, .msg_iovlen = 1 };
    char fd_buf[CMSG_SPACE(sizeof(int))];
    msg.msg_control = fd_buf;
    msg.msg_controllen = sizeof(fd_buf);

    struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type = SCM_RIGHTS;
    cmsg->cmsg_len = CMSG_LEN(sizeof(int));
    *((int *) CMSG_DATA(cmsg)) = fd;

    if (sendmsg(sock, &msg, 0) < 0) perror("sendmsg");
}

// Helper: Check if we know this file
static int is_known(shm_tracker_t list[MAX_FILES], const char *name) {
    for (int i = 0; i < MAX_FILES; i++) {
        if (list[i].used && strcmp(list[i].name, name) == 0) return 1;
    }
    return 0;
}

// Helper: Add to list
static void add_to_list(shm_tracker_t list[MAX_FILES], const char *name) {
    if (is_known(list, name)) return;
    for (int i = 0; i < MAX_FILES; i++) {
        if (!list[i].used) {
            strcpy(list[i].name, name);
            list[i].used = 1;
            return;
        }
    }
}

int main(void) {
    shm_tracker_t shm_list[MAX_FILES];
    memset(shm_list, 0, sizeof(shm_list));

    // 1. Setup Socket
    unlink(SOCKET_PATH);
    int server_fd = socket(AF_UNIX, SOCK_SEQPACKET, 0);
    if (server_fd < 0) die("socket");

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strcpy(addr.sun_path, SOCKET_PATH);

    if (bind(server_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) die("bind");
    if (listen(server_fd, 10) < 0) die("listen");

    // 2. Main Loop
    while (1) {
        int client_fd = accept(server_fd, NULL, NULL);
        if (client_fd < 0) continue;

        char req[32];
        if (recv_string(client_fd, req, sizeof(req)) <= 0) {
            close(client_fd);
            continue;
        }

        // --- STOP COMMAND ---
        if (strcmp(req, "STOP") == 0) {
            close(client_fd);
            break; // Break loop to cleanup
        }

        // --- READ/WRITE COMMANDS ---
        if (strcmp(req, "READ") == 0 || strcmp(req, "WRITE") == 0) {
            char filename[128];
            if (recv_string(client_fd, filename, sizeof(filename)) > 0) {
                
                // Name shared memory "/filename"
                char shm_name[140];
                snprintf(shm_name, sizeof(shm_name), "/%s", filename);

                // Check if new
                int is_new = !is_known(shm_list, shm_name);
                add_to_list(shm_list, shm_name);

                // Open/Create SHM
                int shm_fd = shm_open(shm_name, O_RDWR | O_CREAT, 0666);
                if (shm_fd < 0) die("shm_open");

                ftruncate(shm_fd, sizeof(sem_t));
                sem_t *sem = mmap(NULL, sizeof(sem_t), PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
                
                // Only init if it's new
                if (is_new) sem_init(sem, 1, 1);

                // SERVER LOCKS (This blocks the whole server if file is busy)
                sem_wait(sem);

                // Cleanup mapping (we don't need it anymore, client has it)
                munmap(sem, sizeof(sem_t));
                close(shm_fd);

                // Open File
                int file_fd;
                if (strcmp(req, "READ") == 0)
                    file_fd = open(filename, O_RDONLY | O_CREAT, 0666);
                else 
                    file_fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0666);

                // Send to client
                if (file_fd >= 0) {
                    send_shm_and_fd(client_fd, shm_name, file_fd);
                    close(file_fd);
                }
            }
        }
        close(client_fd);
    }

    // 3. Cleanup (After STOP)
    close(server_fd);
    for (int i = 0; i < MAX_FILES; i++) {
        if (shm_list[i].used) {
            int fd = shm_open(shm_list[i].name, O_RDWR, 0666);
            if (fd >= 0) {
                sem_t *sem = mmap(NULL, sizeof(sem_t), PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
                if (sem != MAP_FAILED) {
                    sem_wait(sem); // Wait for clients
                    sem_destroy(sem);
                    munmap(sem, sizeof(sem_t));
                }
                close(fd);
                shm_unlink(shm_list[i].name);
            }
        }
    }
    unlink(SOCKET_PATH);
    return 0;
}