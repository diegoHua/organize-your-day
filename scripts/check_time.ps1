# check_time.ps1
# Outputs current local time for the planning system.
# The agent MUST run this before presenting, listing, or scheduling any task.

Get-Date -Format "yyyy-MM-dd HH:mm:ss"
