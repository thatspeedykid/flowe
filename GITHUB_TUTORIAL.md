# How to Put flo on GitHub

Step-by-step from zero to public repo.

---

## 1. Create a GitHub account

Go to https://github.com and sign up if you don't have an account.

---

## 2. Install Git

Download from https://git-scm.com/download/win and install with default settings.

Open a new Command Prompt after installing and confirm it works:
```
git --version
```

---

## 3. Set your Git identity (one time only)

```
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

---

## 4. Create the repo on GitHub

1. Click the **+** in the top right → **New repository**
2. Name it: `flo`
3. Description: `Simple budget app and tracking`
4. Set to **Public**
5. Leave everything else unchecked (no README, no .gitignore — we have those already)
6. Click **Create repository**

You'll land on a page with a URL like:
```
https://github.com/YourUsername/flo
```
Copy that URL — you'll need it in step 6.

---

## 5. Set up the local repo

Open Command Prompt in the `flo` folder (the one containing README.md):

```
cd C:\path\to\flo
git init
git add .
git commit -m "Initial commit"
```

---

## 6. Connect and push to GitHub

```
git remote add origin https://github.com/YourUsername/flo.git
git branch -M main
git push -u origin main
```

It will ask for your GitHub username and password.

> **Note:** GitHub no longer accepts your account password here.
> You need a **Personal Access Token** instead. See step 7.

---

## 7. Create a Personal Access Token (if needed)

1. GitHub → click your profile photo → **Settings**
2. Scroll down → **Developer settings** (bottom left)
3. **Personal access tokens** → **Tokens (classic)**
4. **Generate new token (classic)**
5. Give it a name like `flo-push`
6. Check the **repo** scope
7. Click **Generate token**
8. **Copy the token immediately** — you won't see it again

When Git asks for your password, paste the token instead.

---

## 8. Add screenshots

After launching flo and setting up some data:

1. Take a screenshot of each tab (Win + Shift + S)
2. Save them as:
   - `github/screenshots/budget.png`
   - `github/screenshots/snowball.png`
   - `github/screenshots/networth.png`
   - `github/screenshots/events.png`
3. Push them:
```
git add github/screenshots/
git commit -m "Add screenshots"
git push
```

The README will automatically show them on your GitHub page.

---

## 9. Update the README with your username

Open `README.md` and replace `yourusername` with your actual GitHub username
in the clone URL:

```
git clone https://github.com/YourUsername/flo
```

Then push:
```
git add README.md
git commit -m "Fix clone URL"
git push
```

---

## Releasing a built exe (optional)

To share a downloadable `flo.exe` with people who don't have Python:

1. Build the exe: run `build_windows.bat`
2. On GitHub → your repo → **Releases** (right sidebar)
3. **Create a new release**
4. Tag: `v1.0.0`
5. Title: `flo v1.0.0`
6. Drag `src/dist/flo.exe` into the assets box
7. Publish release

Users can then download `flo.exe` directly — no Python needed.

---

## Day-to-day updates

Whenever you make changes:

```
git add .
git commit -m "Describe what you changed"
git push
```

That's it. GitHub keeps the full history of every change.

---

## Quick reference

| Command | What it does |
|---|---|
| `git status` | See what files changed |
| `git add .` | Stage all changes |
| `git commit -m "message"` | Save a snapshot |
| `git push` | Upload to GitHub |
| `git pull` | Download latest from GitHub |
| `git log --oneline` | See commit history |
