I accidentally committed a credential into this repository and it has already been pushed to origin.

Context:
- I rotated the credential, but the old value is still present in Git history
- I need to clean default branch plus two release branches
- I am on Windows PowerShell
- I plan to use `git filter-repo --replace-text`
- Team members already cloned this repo

Please provide a safe remediation workflow with commands, including how to create the replace-text file correctly on Windows so the rewrite actually matches.
