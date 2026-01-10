# Installing Portfolio Update Command

To run `make portfolio-update` from anywhere, you have two options:

## Option 1: Create a Shell Alias (Recommended)

Add this to your `~/.bashrc` or `~/.zshrc`:

```bash
alias portfolio-update='make -C "/home/goce/Desktop/Cursor projects/Pi-version-control" portfolio-update'
```

Then reload your shell:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

Now you can run `portfolio-update` from anywhere!

## Option 2: Install Wrapper Script to PATH

```bash
# Copy the wrapper script to /usr/local/bin (run from your home directory or full path)
cd "/home/goce/Desktop/Cursor projects/Pi-version-control"
sudo cp "scripts/portfolio-update-wrapper.sh" /usr/local/bin/portfolio-update
sudo chmod +x /usr/local/bin/portfolio-update

# Now you can run from anywhere:
portfolio-update
```

## Option 3: Use Make with -f Flag

If you just want to run it with make, you can create an alias:

```bash
alias lab-make='make -C "/home/goce/Desktop/Cursor projects/Pi-version-control"'
```

Then use it like:
```bash
lab-make portfolio-update
lab-make health
lab-make status
```

## Recommended: Option 1 (Alias)

The alias is the simplest and doesn't require sudo permissions.

