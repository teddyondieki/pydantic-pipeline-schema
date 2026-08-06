FROM python:3.12-slim

WORKDIR /app

# The pre-fix source checkout is bundled with a single cleaned base commit.
# It has no remote or later refs, so Git history cannot reveal the upstream fix.
COPY repo/ /app/

# Install the application in editable mode. Agents edit /app, and the verifier
# must execute those edits rather than a copied wheel in site-packages.
RUN python -m pip install --no-cache-dir -e . pytest==8.4.1 pytest-json-ctrf==0.3.5
