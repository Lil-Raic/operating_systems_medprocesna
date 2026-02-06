#!/usr/bin/env bash

source test_common.sh
source test_common_lib.sh
source test_format_lib.sh
source test_localization_lib.sh

################################################################################
# Init
################################################################################

cd $(mktemp -d -p .)

################################################################################
# Header
################################################################################

echo_test_title "$0"; echo
printf_local "This test checks:"; echo
printf_local "  - writing to single file"; echo
printf_local "  - writing to multiple files"; echo

################################################################################
# Subtests
################################################################################

# Subtest 1
print_subtest_title "pisanje ene zbirke"
server_start
server_is_running
pipe_1="$(create_pipe)"
send_flag_w "${pipe_1}" "temp_1.txt"
write_to_pipe "${pipe_1}" "lorem ipsum dolor sit amet"
server_stop
server_is_stopped
print_file "temp_1.txt"
read -r -d '' expected_output << EOF
strežnik zagnan
pošiljam zastavico '-w'
pišem v zbirko
pošiljam zastavico '-s'
strežnik ustavljen
++ vsebina zbirke temp_1.txt:
lorem ipsum dolor sit amet
--
EOF
check "${ACTUAL_EXIT_STATUS}" 0 "$(echo "${ACTUAL_OUTPUT}" | tail -n +2)" "${expected_output}"

# Subtest 2
print_subtest_title "zaporedno pisanje več zbirk"
server_start
server_is_running
pipe_1="$(create_pipe)"
send_flag_w "${pipe_1}" "temp_1.txt"
write_to_pipe "${pipe_1}" "lorem ipsum dolor sit amet"
print_file "temp_1.txt"
pipe_2="$(create_pipe)"
send_flag_w "${pipe_2}" "temp_2.txt"
write_to_pipe "${pipe_2}" "consectetur adipiscing elit"
print_file "temp_2.txt"
pipe_3="$(create_pipe)"
send_flag_w "${pipe_3}" "temp_3.txt"
write_to_pipe "${pipe_3}" "sed do eiusmod tempor incididunt"
print_file "temp_3.txt"
server_stop
server_is_stopped
read -r -d '' expected_output << EOF
strežnik zagnan
pošiljam zastavico '-w'
pišem v zbirko
++ vsebina zbirke temp_1.txt:
lorem ipsum dolor sit amet
--
pošiljam zastavico '-w'
pišem v zbirko
++ vsebina zbirke temp_2.txt:
consectetur adipiscing elit
--
pošiljam zastavico '-w'
pišem v zbirko
++ vsebina zbirke temp_3.txt:
sed do eiusmod tempor incididunt
--
pošiljam zastavico '-s'
strežnik ustavljen
EOF
check "${ACTUAL_EXIT_STATUS}" 0 "$(echo "${ACTUAL_OUTPUT}" | tail -n +2)" "${expected_output}"

# Subtest 3
print_subtest_title "vzporedno pisanje več zbirk"
server_start
server_is_running
pipe_1="$(create_pipe)"
send_flag_w "${pipe_1}" "temp_1.txt"
pipe_2="$(create_pipe)"
send_flag_w "${pipe_2}" "temp_2.txt"
pipe_3="$(create_pipe)"
send_flag_w "${pipe_3}" "temp_3.txt"
write_to_pipe "${pipe_1}" "lorem ipsum dolor sit amet"
print_file "temp_1.txt"
write_to_pipe "${pipe_2}" "consectetur adipiscing elit"
print_file "temp_2.txt"
write_to_pipe "${pipe_3}" "sed do eiusmod tempor incididunt"
print_file "temp_3.txt"
server_stop
server_is_stopped
read -r -d '' expected_output << EOF
strežnik zagnan
pošiljam zastavico '-w'
pošiljam zastavico '-w'
pošiljam zastavico '-w'
pišem v zbirko
++ vsebina zbirke temp_1.txt:
lorem ipsum dolor sit amet
--
pišem v zbirko
++ vsebina zbirke temp_2.txt:
consectetur adipiscing elit
--
pišem v zbirko
++ vsebina zbirke temp_3.txt:
sed do eiusmod tempor incididunt
--
pošiljam zastavico '-s'
strežnik ustavljen
EOF
check "${ACTUAL_EXIT_STATUS}" 0 "$(echo "${ACTUAL_OUTPUT}" | tail -n +2)" "${expected_output}"

# Subtest 4
print_subtest_title "obratno vzporedno pisanje več zbirk"
server_start
server_is_running
pipe_1="$(create_pipe)"
send_flag_w "${pipe_1}" "temp_1.txt"
pipe_2="$(create_pipe)"
send_flag_w "${pipe_2}" "temp_2.txt"
pipe_3="$(create_pipe)"
send_flag_w "${pipe_3}" "temp_3.txt"
write_to_pipe "${pipe_3}" "sed do eiusmod tempor incididunt"
print_file "temp_3.txt"
write_to_pipe "${pipe_2}" "consectetur adipiscing elit"
print_file "temp_2.txt"
write_to_pipe "${pipe_1}" "lorem ipsum dolor sit amet"
print_file "temp_1.txt"
server_stop
server_is_stopped
read -r -d '' expected_output << EOF
strežnik zagnan
pošiljam zastavico '-w'
pošiljam zastavico '-w'
pošiljam zastavico '-w'
pišem v zbirko
++ vsebina zbirke temp_3.txt:
sed do eiusmod tempor incididunt
--
pišem v zbirko
++ vsebina zbirke temp_2.txt:
consectetur adipiscing elit
--
pišem v zbirko
++ vsebina zbirke temp_1.txt:
lorem ipsum dolor sit amet
--
pošiljam zastavico '-s'
strežnik ustavljen
EOF
check "${ACTUAL_EXIT_STATUS}" 0 "$(echo "${ACTUAL_OUTPUT}" | tail -n +2)" "${expected_output}"

# Subtest 5
print_subtest_title "večkratno pisanje ene zbirke"
server_start
server_is_running
pipe_1="$(create_pipe)"
send_flag_w "${pipe_1}" "temp_1.txt"
pipe_2="$(create_pipe)"
send_flag_w "${pipe_2}" "temp_1.txt"
pipe_3="$(create_pipe)"
send_flag_w "${pipe_3}" "temp_1.txt"
write_to_pipe "${pipe_1}" "lorem ipsum dolor sit amet"
print_file "temp_1.txt"
write_to_pipe "${pipe_2}" "consectetur adipiscing elit"
print_file "temp_1.txt"
write_to_pipe "${pipe_3}" "sed do eiusmod tempor incididunt"
print_file "temp_1.txt"
server_stop
server_is_stopped
read -r -d '' expected_output << EOF
strežnik zagnan
pošiljam zastavico '-w'
pošiljam zastavico '-w'
pošiljam zastavico '-w'
pišem v zbirko
++ vsebina zbirke temp_1.txt:
--
pišem v zbirko
++ vsebina zbirke temp_1.txt:
--
pišem v zbirko
++ vsebina zbirke temp_1.txt:
sed do eiusmod tempor incididunt
--
pošiljam zastavico '-s'
strežnik ustavljen
EOF
check "${ACTUAL_EXIT_STATUS}" 0 "$(echo "${ACTUAL_OUTPUT}" | tail -n +2)" "${expected_output}"

################################################################################
# Footer
################################################################################

print_footer

################################################################################
# Deinit
################################################################################

pkill -SIGKILL -f "${EXEC_SERVER}"
pkill -SIGKILL -f "${EXEC_CLIENT}"

exit "${TEST_RESULT}"
