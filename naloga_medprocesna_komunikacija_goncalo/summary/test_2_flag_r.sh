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
printf_local "  - reading from single file"; echo
printf_local "  - reading from multiple files"; echo

################################################################################
# Subtests
################################################################################

# Subtest 1
print_subtest_title "branje ene zbirke"
server_start
server_is_running
create_file "temp_1.txt" "lorem ipsum dolor sit amet"
send_flag_r "temp_1.txt"
server_stop
server_is_stopped
read -r -d '' expected_output << EOF
strežnik zagnan
pošiljam zastavico '-r'
++ vsebina zbirke temp_1.txt:
lorem ipsum dolor sit amet
--
pošiljam zastavico '-s'
strežnik ustavljen
EOF
check "${ACTUAL_EXIT_STATUS}" 0 "$(echo "${ACTUAL_OUTPUT}" | tail -n +2)" "${expected_output}"

# Subtest 2
print_subtest_title "zaporedno branje več zbirk"
server_start
server_is_running
create_file "temp_1.txt" "lorem ipsum dolor sit amet"
send_flag_r "temp_1.txt"
create_file "temp_2.txt" "consectetur adipiscing elit"
send_flag_r "temp_2.txt"
create_file "temp_3.txt" "sed do eiusmod tempor incididunt"
send_flag_r "temp_3.txt"
server_stop
server_is_stopped
read -r -d '' expected_output << EOF
strežnik zagnan
pošiljam zastavico '-r'
++ vsebina zbirke temp_1.txt:
lorem ipsum dolor sit amet
--
pošiljam zastavico '-r'
++ vsebina zbirke temp_2.txt:
consectetur adipiscing elit
--
pošiljam zastavico '-r'
++ vsebina zbirke temp_3.txt:
sed do eiusmod tempor incididunt
--
pošiljam zastavico '-s'
strežnik ustavljen
EOF
check "${ACTUAL_EXIT_STATUS}" 0 "$(echo "${ACTUAL_OUTPUT}" | tail -n +2)" "${expected_output}"

# Subtest 3
print_subtest_title "večkratno branje ene zbirke"
server_start
server_is_running
create_file "temp_1.txt" "lorem ipsum dolor sit amet"
send_flag_r "temp_1.txt"
send_flag_r "temp_1.txt"
send_flag_r "temp_1.txt"
server_stop
server_is_stopped
read -r -d '' expected_output << EOF
strežnik zagnan
pošiljam zastavico '-r'
++ vsebina zbirke temp_1.txt:
lorem ipsum dolor sit amet
--
pošiljam zastavico '-r'
++ vsebina zbirke temp_1.txt:
lorem ipsum dolor sit amet
--
pošiljam zastavico '-r'
++ vsebina zbirke temp_1.txt:
lorem ipsum dolor sit amet
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
