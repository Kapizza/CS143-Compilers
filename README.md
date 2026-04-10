# CS143 — Compilers

Stanford CS143 programming assignments solved in Cool (Classroom Object-Oriented Language).

---

## Setup (WSL on Windows)

### Step 1 — Install WSL

In PowerShell (run as Administrator), if not already done:
```powershell
wsl --install
```
Restart when prompted. This installs Ubuntu by default.

### Step 2 — Run the setup script

Open your WSL terminal and run:
```bash
cd /mnt/c/Users/datog/OneDrive/Desktop/git/CS143
bash setup-wsl.sh
source ~/.bashrc
```

This installs `coolc`, `spim`, and all required build tools.
Tools are installed to `/usr/class/bin/`.

### Step 3 — Compile and run PA1

```bash
cd /mnt/c/Users/datog/OneDrive/Desktop/git/CS143/assignments/PA1
coolc stack.cl atoi.cl        # compile → stack.s
spim -file stack.s            # run interactively
gmake test                    # run against stack.test and diff with reference
# Note: CLASSDIR is set to /usr/class in the Makefile
```

---

## Assignments

| # | Topic | Source |
|---|-------|--------|
| PA1 | Stack machine interpreter in Cool | [assignments/PA1/](assignments/PA1/) |
| PA2 | Lexical analysis |Coming Soon! |
