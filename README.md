# Unity License Activator

Automatically generates your free **Unity Personal** `.ulf` license file using GitHub Actions.

## How to run it (on your phone)

### Step 1 — Add your Unity credentials (one time only)

1. Open your repo on GitHub → **Settings** → **Secrets and variables** → **Actions**
2. Tap **New repository secret** and add two secrets:

| Name | Value |
|------|-------|
| `UNITY_EMAIL` | Your Unity account email |
| `UNITY_PASSWORD` | Your Unity account password |

### Step 2 — Run the workflow

1. Go to the **Actions** tab → select **Acquire Unity License**
2. Tap **Run workflow** → **Run workflow**
3. Wait for both jobs to finish (green checkmarks)

### Step 3 — Download your license

1. When the run finishes, open the run page
2. Scroll to **Artifacts** → download **`unity-license-ulf`**
3. Inside is your `.ulf` file — this IS your license

If it fails, download the **`error-screenshot`** artifact to see where it stopped.

## Notes

- Personal licenses expire occasionally — just run the workflow again to get a fresh `.ulf`
- Never commit your email/password or the `.ulf` file into this repo
- Your credentials are stored only as encrypted GitHub secrets
