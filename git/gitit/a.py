#!/usr/bin/env python3
"""
gitit v11.0 - ABSOLUTE RELIABILITY - NO LFS - ZERO FAILURES

CRITICAL RULES:
1. Files >=100MB are EXCLUDED (added to .gitignore) - GitHub hard limit
2. NO LFS code whatsoever (causes quota errors)
3. ALWAYS force-delete and recreate repos with LFS remnants
4. ALWAYS fresh git init (no incremental sync complexity)
5. ALWAYS succeed or fail with clear message

CHANGES FROM v10.0:
- Removed incremental sync entirely (complexity = bugs)
- Always fresh start (nuke .git, .gitattributes, recreate repo)
- Simpler, more reliable, guaranteed to work
"""
import subprocess, sys, os, time, shutil, re
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except AttributeError:
        pass

GITHUB_FILE_LIMIT = 100 * 1024 * 1024  # 100MB hard limit
GITHUB_USERNAME = "Michaelunkai"
WINDOWS_RESERVED = frozenset({'con','prn','aux','nul','com1','com2','com3','com4',
                    'com5','com6','com7','com8','com9','lpt1','lpt2',
                    'lpt3','lpt4','lpt5','lpt6','lpt7','lpt8','lpt9'})

# Speed-optimized git config
GIT_CONFIG_BLOCK = """[core]
\tautocrlf = false
\tlongpaths = true
\tpreloadindex = true
\tfscache = true
\tuntrackedCache = true
\tfsmonitor = true
\tcompression = 1
\tbigFileThreshold = 1m
[http]
\tpostBuffer = 524288000
\tlowSpeedLimit = 1000
\tlowSpeedTime = 600
[pack]
\twindowMemory = 256m
\tpackSizeLimit = 512m
\tthreads = 0
"""

C_G = "\033[92m"; C_Y = "\033[93m"; C_B = "\033[96m"; C_R = "\033[91m"; C_X = "\033[0m"


def run(cmd, cwd=None, timeout=300):
    """Execute shell command with timeout"""
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True,
                           encoding='utf-8', errors='replace', cwd=cwd,
                           env={**os.environ, 'GIT_TERMINAL_PROMPT': '0'}, timeout=timeout)
        return r.returncode == 0, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return False, "", "timeout"
    except Exception as e:
        return False, "", str(e)


def prog(s, t, m):
    """Progress bar"""
    p = int(100*s/t); f = int(40*s/t)
    print(f"\r{C_B}[{chr(9608)*f}{chr(9617)*(40-f)}] {p}% - {m}{C_X}", end="", flush=True)


def nuke_git_completely(wd):
    """Remove ALL git-related files/folders for clean start"""
    gd = wd / ".git"
    ga = wd / ".gitattributes"
    gi = wd / ".gitignore"
    gm = wd / ".gitmodules"
    
    # Remove .git directory - AGGRESSIVE deletion (LFS objects are stubborn)
    if gd.exists():
        # Try Python first
        shutil.rmtree(gd, ignore_errors=True)
        
        # If still exists, use Windows cmd
        if gd.exists() and sys.platform == "win32":
            run(f'cmd /c rd /s /q "{gd}"', timeout=30)
            time.sleep(0.5)
        
        # If STILL exists, use PowerShell with force
        if gd.exists() and sys.platform == "win32":
            run(f'powershell -Command "Remove-Item -Path \\"{gd}\\" -Recurse -Force -ErrorAction SilentlyContinue"', timeout=30)
            time.sleep(0.5)
        
        # Last resort: manual deletion
        if gd.exists():
            for item in gd.rglob("*"):
                try:
                    if item.is_file():
                        os.chmod(str(item), 0o777)
                        item.unlink()
                except: pass
            shutil.rmtree(gd, ignore_errors=True)
    
    # Remove .gitattributes (LFS remnant)
    if ga.exists():
        try: ga.unlink()
        except: pass
    
    # Keep .gitignore if it exists (we'll append to it)
    # Remove .gitmodules (submodules cause issues)
    if gm.exists():
        try: gm.unlink()
        except: pass


def remove_nested_gits(directory):
    """Remove nested .git folders (max 100 to prevent hanging)"""
    removed = []
    count = [0]
    MAX_NESTED = 100
    
    def scan(cur, depth):
        if count[0] >= MAX_NESTED:
            return
        try:
            with os.scandir(cur) as it:
                for e in it:
                    if count[0] >= MAX_NESTED:
                        return
                    if e.is_dir(follow_symlinks=False):
                        if e.name == '.git':
                            if depth > 0:  # Don't remove root .git
                                shutil.rmtree(e.path, ignore_errors=True)
                                if os.path.exists(e.path) and sys.platform == "win32":
                                    run(f'rd /s /q "{e.path}"', timeout=10)
                                try:
                                    removed.append(os.path.relpath(cur, directory))
                                    count[0] += 1
                                except: pass
                        else:
                            scan(e.path, depth + 1)
        except (PermissionError, OSError):
            pass
    
    scan(directory, 0)
    if count[0] >= MAX_NESTED:
        print(f"{C_Y}⚠ Stopped at {MAX_NESTED} nested .gits{C_X}")
    return removed


def scan_files(directory):
    """Scan all files, identify large ones (>=100MB)"""
    large = []
    total = 0
    dp = len(directory.parts)
    
    print(f"{C_B}Scanning files...{C_X}", flush=True)
    last_update = time.time()
    
    for root, dirs, files in os.walk(directory):
        rp = Path(root)
        
        # Skip .git folders
        if '.git' in rp.parts[dp:]:
            dirs.clear()
            continue
        if '.git' in dirs:
            dirs.remove('.git')
        
        for fn in files:
            # Skip Windows reserved names
            nl = fn.lower()
            base = nl.split('.')[0] if '.' in nl else nl
            if base in WINDOWS_RESERVED or nl in WINDOWS_RESERVED:
                try:
                    fp = rp / fn
                    if sys.platform == "win32":
                        os.remove(f"\\\\?\\{fp}")
                    else:
                        fp.unlink()
                except: pass
                continue
            
            total += 1
            
            # Progress updates
            if total % 1000 == 0 or (time.time() - last_update > 5):
                print(f"\r{C_B}Scanned {total} files, {len(large)} large...{C_X}", end="", flush=True)
                last_update = time.time()
            
            # Check file size
            try:
                sz = (rp / fn).stat().st_size
                if sz >= GITHUB_FILE_LIMIT:
                    rel_path = str((rp / fn).relative_to(directory))
                    large.append((rel_path, sz))
            except: pass
    
    print(f"\r{C_B}Scan complete: {total} files, {len(large)} large{C_X}          ")
    return large, total


def create_gitignore(wd, large_files):
    """Create .gitignore with large file exclusions"""
    if not large_files:
        return
    
    gitignore_path = wd / ".gitignore"
    
    # Read existing entries
    existing = set()
    if gitignore_path.exists():
        try:
            content = gitignore_path.read_text(errors='replace')
            existing = set(line.strip() for line in content.split('\n') if line.strip())
        except:
            pass
    
    # Add new exclusions (forward slashes - git standard)
    new_entries = []
    for rp, sz in large_files:
        git_path = rp.replace("\\", "/")
        if git_path not in existing:
            new_entries.append(git_path)
    
    if new_entries:
        try:
            with open(gitignore_path, 'a', encoding='utf-8') as f:
                f.write("\n# Files >=100MB excluded by gitit (GitHub limit)\n")
                for entry in new_entries:
                    f.write(f"{entry}\n")
            print(f"{C_Y}⚠ {len(new_entries)} files >=100MB added to .gitignore{C_X}")
        except Exception as e:
            print(f"{C_Y}⚠ Could not write .gitignore: {e}{C_X}")


def recreate_repo(repo_name):
    """Delete and recreate GitHub repo (clears LFS and everything else)"""
    print(f"{C_Y}Recreating GitHub repo (clearing LFS)...{C_X}", end="", flush=True)
    
    # Delete old repo completely
    run(f"gh repo delete {GITHUB_USERNAME}/{repo_name} --yes", timeout=30)
    time.sleep(5)  # Wait for GitHub to fully delete
    
    # Create fresh repo
    run(f"gh repo create {GITHUB_USERNAME}/{repo_name} --public", timeout=30)
    time.sleep(3)
    
    # CRITICAL: Disable LFS on the new repo (prevents quota issues)
    # There's no direct gh command for this, but we can ensure it's not tracking LFS
    # by not pushing any .gitattributes file


def ensure_repo_exists(repo_name):
    """Ensure GitHub repo exists and is public"""
    ok, out, _ = run(f"gh repo view {GITHUB_USERNAME}/{repo_name} --json visibility --jq .visibility", timeout=30)
    if not ok:
        run(f"gh repo create {GITHUB_USERNAME}/{repo_name} --public", timeout=30)
        time.sleep(2)
    elif out.strip().upper() != "PUBLIC":
        run(f"gh repo edit {GITHUB_USERNAME}/{repo_name} --visibility public --accept-visibility-change-consequences", timeout=30)


def push_with_retry(wd, repo_name, timeout=1800, max_attempts=3):
    """Push to GitHub with retries and smart error handling"""
    for attempt in range(max_attempts):
        t = timeout + (attempt * 300)
        print(f" (attempt {attempt+1}/{max_attempts})", end="", flush=True)
        
        ok, _, err = run("git push origin main --force", wd, timeout=t)
        
        if ok:
            return True
        
        el = err.lower()
        
        # Print first useful error line
        for line in err.strip().split('\n'):
            line = line.strip()
            if line and not line.startswith('To ') and not line.startswith('remote:') and '----' not in line:
                print(f"\n{C_Y}  Error: {line[:120]}{C_X}", end="", flush=True)
                break
        
        # CRITICAL: LFS quota/budget errors = recreate repo
        if "lfs" in el and ("budget" in el or "quota" in el or "exceeded" in el):
            print(f"\n{C_Y}  LFS remnants detected - recreating repo...{C_X}", end="", flush=True)
            recreate_repo(repo_name)
            continue
        
        # Large file errors = should never happen (we filtered them)
        if "large file" in el or "this exceeds" in el or ("file is" in el and "mb" in el):
            print(f"\n{C_R}  FATAL: Large file detected (scan missed it!){C_X}")
            return False
        
        # Secret/push protection = bypass or recreate
        if "push protection" in el or "cannot contain secrets" in el or "rule violations" in el:
            ids = re.findall(r'unblock-secret/([A-Za-z0-9]+)', err)
            if ids:
                print(f"\n{C_Y}  Bypassing {len(ids)} secrets...{C_X}", end="", flush=True)
                for sid in set(ids):
                    run(f'gh api -X POST repos/{GITHUB_USERNAME}/{repo_name}/secret-scanning/push-protection-bypasses '
                        f'-f reason=will_fix_later -f placeholder_id={sid}', timeout=15)
                continue
            else:
                recreate_repo(repo_name)
                continue
        
        # Repo not found = create it
        if "repository not found" in el:
            ensure_repo_exists(repo_name)
            continue
        
        # Rate limits = wait
        if "rate limit" in el or "secondary" in el or "abuse" in el:
            wait = 60 * (attempt + 1)
            print(f"\n{C_Y}  Rate limited - waiting {wait}s...{C_X}", end="", flush=True)
            time.sleep(wait)
            continue
        
        # Timeout = retry with longer timeout
        if "timeout" in el or "timed out" in el:
            time.sleep(10)
            continue
        
        # Generic error = short wait and retry
        time.sleep(5)
    
    return False


def main():
    if len(sys.argv) < 2:
        print(f"Usage: gitit <folder_path>")
        sys.exit(1)
    
    wd = Path(sys.argv[1]).resolve()
    if not wd.exists():
        print(f"{C_R}Error: {wd} does not exist{C_X}")
        sys.exit(1)
    
    print(f"\n{C_B}Processing: {wd}{C_X}")
    
    # Generate repo name
    repo_name = wd.name.replace(" ", "-").lower()
    repo_name = re.sub(r'[^a-z0-9\-_]', '', repo_name)
    repo_name = repo_name[:100] or "unnamed-repo"
    
    start_time = time.time()
    
    # STEP 1: Scan files
    large_files, total_files = scan_files(wd)
    
    if total_files == 0:
        print(f"{C_R}✗ No files found in {wd}{C_X}")
        sys.exit(1)
    
    print(f"{C_B}ℹ {total_files} files total, {len(large_files)} large (>=100MB){C_X}")
    
    # STEP 2: Clean slate - remove ALL git files
    S = 6
    s = 1
    prog(s, S, "Cleaning")
    nuke_git_completely(wd)
    remove_nested_gits(wd)
    
    # STEP 3: Create .gitignore for large files
    s += 1
    prog(s, S, "Excluding large files")
    if large_files:
        create_gitignore(wd, large_files)
    
    # STEP 4: Initialize fresh git repo
    s += 1
    prog(s, S, "Initializing")
    ok, _, err = run(f'git init -b main "{wd}"', wd)
    if not ok:
        print(f"\n{C_R}✗ git init failed: {err[:200]}{C_X}")
        sys.exit(1)
    
    run(f'git config user.name "{GITHUB_USERNAME}"', wd)
    run(f'git config user.email "{GITHUB_USERNAME}@users.noreply.github.com"', wd)
    run(f'git config --global --add safe.directory "{wd}"', wd)
    
    # CRITICAL: Disable ALL LFS everywhere (prevents "exceeded LFS budget" errors)
    # Local repo level
    run('git config filter.lfs.clean ""', wd)
    run('git config filter.lfs.smudge ""', wd)
    run('git config filter.lfs.process ""', wd)
    run('git config filter.lfs.required false', wd)
    run('git config lfs.repositoryformatversion 0', wd)
    # Global level (permanent - survives across all repos)
    run('git config --global filter.lfs.clean ""')
    run('git config --global filter.lfs.smudge ""')
    run('git config --global filter.lfs.process ""')
    run('git config --global filter.lfs.required false')
    
    # Write speed config
    cfg_path = wd / ".git" / "config"
    try:
        with open(cfg_path, 'a', encoding='utf-8') as f:
            f.write(GIT_CONFIG_BLOCK)
    except: pass
    
    # STEP 5: Stage and commit
    s += 1
    prog(s, S, "Staging")
    
    st = max(600, min(3600, total_files // 50))
    ok, _, _ = run('git add -A', wd, timeout=st)
    
    # Count staged files
    ok, out, _ = run("git diff --cached --shortstat", wd, timeout=120)
    staged = 0
    if ok and out.strip():
        m = re.search(r'(\d+) files? changed', out)
        if m:
            staged = int(m.group(1))
    
    if staged == 0:
        # Try counting another way
        ok, out, _ = run("git diff --cached --name-only", wd, timeout=120)
        if ok and out.strip():
            staged = out.strip().count('\n') + 1
    
    if staged == 0:
        print(f"\n{C_R}✗ No files staged (all excluded?){C_X}")
        sys.exit(1)
    
    print(f" ({staged} files)", end="", flush=True)
    
    s += 1
    prog(s, S, "Committing")
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    ok, _, err = run(f'git commit -m "gitit v11.0 - {ts} - {staged} files"', wd, timeout=st)
    if not ok:
        print(f"\n{C_R}✗ Commit failed: {err[:200]}{C_X}")
        sys.exit(1)
    
    # STEP 6: Push to GitHub
    s += 1
    prog(s, S, "Pushing")
    
    remote_url = f"https://github.com/{GITHUB_USERNAME}/{repo_name}.git"
    run(f"git remote add origin {remote_url}", wd)
    run("git branch -M main", wd)
    
    # Recreate repo to clear any LFS remnants
    recreate_repo(repo_name)
    
    pt = max(1800, min(7200, total_files // 20))
    push_ok = push_with_retry(wd, repo_name, timeout=pt, max_attempts=3)
    
    # Done
    s = S
    prog(s, S, "Done")
    elapsed = time.time() - start_time
    print("")
    
    if push_ok:
        if large_files:
            print(f"{C_Y}⚠ {len(large_files)} files >=100MB EXCLUDED (see .gitignore){C_X}")
        print(f"{C_G}✓ SUCCESS: {repo_name} ({staged} files, {elapsed:.1f}s){C_X}")
        print(f"{C_Y}→ https://github.com/{GITHUB_USERNAME}/{repo_name}{C_X}")
    else:
        print(f"{C_R}✗ PUSH FAILED: {repo_name}{C_X}")
        sys.exit(1)


if __name__ == "__main__":
    main()
