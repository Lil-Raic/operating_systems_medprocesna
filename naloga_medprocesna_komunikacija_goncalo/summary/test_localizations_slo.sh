declare -A TEST_LOCALIZATIONS=(
# run_tests.sh
['TEST RESULTS']='REZULTATI TESTOV'
['TEST PASSED']='TEST USPEŠEN'
['TEST FAILED']='TEST NEUSPEŠEN'
['TEST TO BE CHECKED MANUALLY']='TEST BO PREVERJEN ROČNO'

# test_common_lib.sh
['Subtest']='Podtest'
['Actual exit status: ']='Dejanska izhodna vrednost: '
['Expected exit status: ']='Pričakovana izhodna vrednost: '
['Actual output:']='Dejanski izhod:'
['Expected output:']='Pričakovan izhod:'
['Is the same as expected output.']='Je enak kot pričakovan izhod.'
['Is the same as actual output.']='Je enak kot dejanski izhod.'
['Diff between actual and expected outputs:']='Razlika med dejanskim in pričakovanim izhodom:'
['SUBTEST PASSED']='PODTEST USPEŠEN'
['SUBTEST FAILED']='PODTEST NEUSPEŠEN'
['SUBTEST TO BE CHECKED MANUALLY']='PODTEST BO PREVERJEN ROČNO'
['TEST PASSED: All subtests passed.']='TEST USPEŠEN: Vsi podtesti so uspeli.'
['TEST FAILED: At least one subtest failed.']='TEST NEUSPEŠEN: Vsaj en izmed podtestov ni uspel.'
['TEST TO BE CHECKED MANUALLY: At least one subtest to be checked manually.']='TEST BO PREVERJEN ROČNO: Vsaj en izmed podtestov bo preverjen ročno.'

# All Tests
['This test checks:']='Ta test preveri:'

# Test 0
['  - an implementation is available and can be tested (server)']='  - implementacija je na voljo in se lahko preizkusi (strežnik)'
['  - an implementation is available and can be tested (client)']='  - implementacija je na voljo in se lahko preizkusi (odjemalec)'
['looking for executable (server)']='iskanje izvedljivega modula (strežnik)'
['looking for executable (client)']='iskanje izvedljivega modula (odjemalec)'
['Executable not set (server).']='Izvedljiv modul ni nastavljen (strežnik).'
['Executable not set (client).']='Izvedljiv modul ni nastavljen (odjemalec).'
['Executable not found (server):']='Izvedljiv modul ni najden (strežnik):'
['Executable not found (client):']='Izvedljiv modul ni najden (odjemalec):'
['Executable found (server):']='Izvedljiv modul je najden (strežnik):'
['Executable found (client):']='Izvedljiv modul je najden (odjemalec):'
['Could not find valgrind, tests will be incomplete.']='Program valgrind ni bil najden, preizkusi bodo nepopolni.'

# Test 1
['  - immediate server shutdown']='  - takojšnja ustavitev strežnika'
['  - waiting for clients']='  - čakanje odjemalcev'

# Test 2
['  - reading from single file']='  - branje ene zbirke'
['  - reading from multiple files']='  - branje več zbirk'

# Test 3
['  - writing to single file']='  - pisanje ene zbirke'
['  - writing to multiple files']='  - pisanje več zbirk'
)
