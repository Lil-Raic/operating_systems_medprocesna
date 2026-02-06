#include <fcntl.h>
#include <getopt.h>
#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#define READ_WRITE_BUF_SIZE 128
#define MAX_ERROR_LEN 128
#define MAX_FILE_NAME_LEN 128
#define SOCKET_PATH "os.socket"

static void
check_error(int value, const char msg[])
{
    if (value == -1) {
        char buf[MAX_ERROR_LEN];
        snprintf(buf, sizeof(buf), "ERROR (%s)", msg);
        perror(buf);
        exit(EXIT_FAILURE);
    }
}

static void
check_error_ssize(ssize_t value, const char msg[])
{
    if (value == -1) {
        char buf[MAX_ERROR_LEN];
        snprintf(buf, sizeof(buf), "ERROR (%s)", msg);
        perror(buf);
        exit(EXIT_FAILURE);
    }
}

static void
copy_fd_data(int fd_in, int fd_out)
{
    ssize_t n_read;
    char buf[READ_WRITE_BUF_SIZE];
    while((n_read = read(fd_in, buf, sizeof(buf))) > 0) {        
        ssize_t n_write = 0;
        while(n_write < n_read) {
            ssize_t n = write(fd_out, buf + n_write, n_read - n_write);
            check_error_ssize(n, "write");
            n_write += n;
        }
    }
    check_error_ssize(n_read, "read");
}

static int
create_connection()
{
    int data_socket = socket(AF_UNIX, SOCK_SEQPACKET, 0);
    check_error(data_socket, "socket");

    struct sockaddr_un socket_addr = { 0 };
    socket_addr.sun_family = AF_UNIX;
    strncpy(socket_addr.sun_path, SOCKET_PATH, sizeof(socket_addr.sun_path) - 1);
    
    int ret = connect(data_socket, (struct sockaddr *) &socket_addr, sizeof(socket_addr));
    check_error(ret, "connect");

    return data_socket;
}

static void
destroy_connection(int data_socket)
{
    int ret = close(data_socket);
    check_error(ret, "close");
}

static void
send_msg(int data_socket, const char msg[])
{
    ssize_t n = send(data_socket, msg, strlen(msg) + 1, 0);
    check_error_ssize(n, "send");
}

static void
read_shm_name_and_file_descriptor(int data_socket, char *shm_name, int *fd)
{
    // Read shared memory name and file descriptor from unix socket
    struct iovec msg_io = { 0 };
    msg_io.iov_base = shm_name;
    msg_io.iov_len = MAX_FILE_NAME_LEN;

    struct msghdr msg = { 0 };
    msg.msg_iov = &msg_io;
    msg.msg_iovlen = 1;

    char fd_buf[CMSG_SPACE(sizeof(fd))] = { 0 };
    msg.msg_control = fd_buf;
    msg.msg_controllen = sizeof(fd_buf);

    ssize_t n = recvmsg(data_socket, &msg, 0);
    check_error_ssize(n, "recvmsg");

    struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
    *fd = *((int *) CMSG_DATA(cmsg));
}

static void
unlock_file(const char shm_name[])
{
    // Open shared memory
    int shm = shm_open(shm_name, O_RDWR, 0);
    check_error(shm, "shm_open");

    // Map shared memory
    sem_t *sem = mmap(NULL, sizeof(sem_t), PROT_READ | PROT_WRITE, MAP_SHARED, shm, 0);
    if (sem == MAP_FAILED) {
        perror("ERROR (mmap)");
        exit(EXIT_FAILURE);
    }

    // Increment (unlock) semaphore
    int ret = sem_post(sem);
    check_error(ret, "sem_post");

    // Unmap shared memory
    ret = munmap(sem, sizeof(sem_t));
    check_error(ret, "munmap");

    // Close shared memory
    ret = close(shm);
    check_error(ret, "close");
}

static void
server_stop()
{
    int data_socket = create_connection();
    send_msg(data_socket, "STOP");
    destroy_connection(data_socket);
}

static void
server_read_file(const char file_name[])
{
    // Create connection
    int data_socket = create_connection();

    // Send command
    send_msg(data_socket, "READ");

    // Send file name
    send_msg(data_socket, file_name);

    // Read shared memory name and file descriptor from unix socket
    char shm_name[MAX_FILE_NAME_LEN];
    int file_fd = -1;
    read_shm_name_and_file_descriptor(data_socket, shm_name, &file_fd);

    // Read content from file descriptor and write it to standard output
    copy_fd_data(file_fd, 1);

    // Close file descriptor
    int ret = close(file_fd);
    check_error(ret, "close");

    // Unlock file
    unlock_file(shm_name);

    // Destroy connection
    destroy_connection(data_socket);
}

static void
server_write_file(const char file_name[])
{
    // Create connection
    int data_socket = create_connection();

    // Send command
    send_msg(data_socket, "WRITE");

    // Send file name
    send_msg(data_socket, file_name);

    // Read shared memory name and file descriptor from unix socket
    char shm_name[MAX_FILE_NAME_LEN];
    int file_fd = -1;
    read_shm_name_and_file_descriptor(data_socket, shm_name, &file_fd);

    // Read content from standard input and write it to file descriptor
    copy_fd_data(0, file_fd);

    // Close file descriptor
    int ret = close(file_fd);
    check_error(ret, "close");

    // Unlock file
    unlock_file(shm_name);

    // Destroy connection
    destroy_connection(data_socket);
}

static void
print_help()
{
    printf("IME\n");
    printf("    sync_client -- Odjemalec za centralizirano branje in pisanje zbirk.\n");
    printf("\n");
    printf("UPORABA\n");
    printf("    sync_client [-h] [-r zbirka] [-s] [-w zbirka]\n");
    printf("\n");
    printf("ZASTAVICE\n");
    printf("    -h\n");
    printf("        Izpis pomoči z vsemi zastavicami in njihovimi opisi.\n");
    printf("\n");
    printf("    -r zbirka\n");
    printf("        Odpri zbirko za branje.\n");
    printf("\n");
    printf("    -s\n");
    printf("        Ustavi strežnik.\n");
    printf("\n");
    printf("    -w zbirka\n");
    printf("        Odpri zbirko za pisanje.\n");
}

int
main(int argc, char *argv[])
{
    int opt;
    while ((opt = getopt(argc, argv, "hr:sw:")) != -1) {
        switch (opt) {
            case 'h':
                print_help();
                exit(EXIT_SUCCESS);
                break;
            case 'r': // READ
                server_read_file(optarg);
                break;
            case 's': // STOP
                server_stop();
                break;
            case 'w': // WRITE
                server_write_file(optarg);
                break;
            default:
                exit(EXIT_FAILURE);
                break;
        }
    }

    return EXIT_SUCCESS;
}
