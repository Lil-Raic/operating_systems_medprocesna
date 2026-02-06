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
printf_local "  - immediate server shutdown"; echo
printf_local "  - waiting for clients"; echo

################################################################################
# Subtests
################################################################################

# Subtest 1
print_subtest_title "takojšnja ustavitev strežnika"
server_start
server_is_running
server_stop
server_is_stopped
read -r -d '' expected_output << EOF
strežnik zagnan
pošiljam zastavico '-s'
strežnik ustavljen
EOF
check "${ACTUAL_EXIT_STATUS}" 0 "$(echo "${ACTUAL_OUTPUT}" | tail -n +2)" "${expected_output}"

# Subtest 2
print_subtest_title "čakanje odjemalcev"
server_start
server_is_running
pipe_1="$(create_pipe)"
send_flag_w "${pipe_1}" "temp_1.txt"
pipe_2="$(create_pipe)"
send_flag_w "${pipe_2}" "temp_2.txt"
server_stop
server_is_stopped
write_to_pipe "${pipe_1}" "lorem ipsum"
server_is_stopped
write_to_pipe "${pipe_2}" "dolor sit amet"
server_is_stopped
read -r -d '' expected_output << EOF
strežnik zagnan
pošiljam zastavico '-w'
pošiljam zastavico '-w'
pošiljam zastavico '-s'
pišem v zbirko
pišem v zbirko
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
