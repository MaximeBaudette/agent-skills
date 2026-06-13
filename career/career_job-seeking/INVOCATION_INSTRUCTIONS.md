# Manual Invocation Instructions for Digest Email

To generate a digest email that includes **all** active job offers (instead of limiting to 3 per tier), run the script with the `--all` flag:

```bash
python /home/mars/.hermes/profiles/career-manager/skills/career_job-seeking/scripts/generate_digest.py --all
```

### What the flag does
- When `--all` is present, the script will include **every unreviewed offer** in each tier in the digest.
- Without `--all`, only the top 3 offers per tier are included.

### Prerequisites
- Ensure the script file exists at:
  `/home/mars/.hermes/profiles/career-manager/skills/career_job-seeking/scripts/generate_digest.py`
- The script has already been updated with the `--all` logic.

### Example
Running the command will produce a formatted digest in `/tmp/digest_body.txt` and send it to your configured email address.

Feel free to run the command whenever you want a comprehensive view of all active opportunities.