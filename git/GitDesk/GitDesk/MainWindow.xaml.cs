using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Media;
using System.Windows.Threading;
using LibGit2Sharp;

namespace GitDesk
{
    public partial class MainWindow : Window
    {
        private Repository? _repo;
        private string? _repoPath;
        private ObservableCollection<FileChange> _changedFiles = new();
        private ObservableCollection<CommitInfo> _history = new();
        private ObservableCollection<BranchInfo> _branches = new();
        private ObservableCollection<string> _stashes = new();
        private ObservableCollection<string> _tags = new();
        private ObservableCollection<RemoteInfo> _remotes = new();
        private DispatcherTimer? _refreshTimer;
        private FileSystemWatcher? _watcher;

        public MainWindow()
        {
            InitializeComponent();
            ChangedFilesList.ItemsSource = _changedFiles;
            HistoryList.ItemsSource = _history;
            BranchList.ItemsSource = _branches;
            StashList.ItemsSource = _stashes;
            TagList.ItemsSource = _tags;
            RemoteList.ItemsSource = _remotes;

            WelcomeView.RepoSelected += path =>
            {
                string repoRoot = Repository.Discover(path) ?? "";
                if (!string.IsNullOrEmpty(repoRoot))
                    OpenRepo(repoRoot);
                else
                    OpenRepo(path);
            };

            // Keyboard shortcuts
            InputBindings.Add(new System.Windows.Input.KeyBinding(
                new RelayCommand(_ => OpenRepo_Click(this, new RoutedEventArgs())),
                System.Windows.Input.Key.O, System.Windows.Input.ModifierKeys.Control));
            InputBindings.Add(new System.Windows.Input.KeyBinding(
                new RelayCommand(_ => { if (_repo != null) { Commands.Stage(_repo, "*"); RefreshChanges(); SetStatus("All staged."); } }),
                System.Windows.Input.Key.A, System.Windows.Input.ModifierKeys.Control | System.Windows.Input.ModifierKeys.Shift));
            InputBindings.Add(new System.Windows.Input.KeyBinding(
                new RelayCommand(_ => Fetch_Click(this, new RoutedEventArgs())),
                System.Windows.Input.Key.F, System.Windows.Input.ModifierKeys.Control | System.Windows.Input.ModifierKeys.Shift));
            InputBindings.Add(new System.Windows.Input.KeyBinding(
                new RelayCommand(_ => Pull_Click(this, new RoutedEventArgs())),
                System.Windows.Input.Key.P, System.Windows.Input.ModifierKeys.Control | System.Windows.Input.ModifierKeys.Shift));
            InputBindings.Add(new System.Windows.Input.KeyBinding(
                new RelayCommand(_ => Push_Click(this, new RoutedEventArgs())),
                System.Windows.Input.Key.U, System.Windows.Input.ModifierKeys.Control | System.Windows.Input.ModifierKeys.Shift));
            InputBindings.Add(new System.Windows.Input.KeyBinding(
                new RelayCommand(_ => RefreshAll()),
                System.Windows.Input.Key.F5, System.Windows.Input.ModifierKeys.None));
        }

        private void SetStatus(string msg)
        {
            StatusText.Text = msg;
        }

        private string RunGit(string args)
        {
            if (_repoPath == null) return "";
            var psi = new ProcessStartInfo("git", args)
            {
                WorkingDirectory = _repoPath,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };
            var proc = Process.Start(psi);
            if (proc == null) return "";
            string output = proc.StandardOutput.ReadToEnd();
            proc.WaitForExit(10000);
            return output;
        }

        private void OpenRepo(string path)
        {
            try
            {
                _repo?.Dispose();
                _repo = new Repository(path);
                _repoPath = path;
                RepoNameText.Text = Path.GetFileName(path.TrimEnd('\\', '/'));
                SetStatus($"Opened: {path}");
                WelcomeView.Visibility = Visibility.Collapsed;
                WelcomePanel.AddRecent(path);
                SetupFileWatcher(path);
                RefreshAll();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Not a valid Git repository:\n{ex.Message}", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void RefreshAll()
        {
            if (_repo == null) return;
            RefreshChanges();
            RefreshHistory();
            RefreshBranches();
            RefreshStashes();
            RefreshTags();
            RefreshRemotes();
            UpdateBranchBar();
        }

        private void RefreshChanges()
        {
            if (_repo == null) return;
            _changedFiles.Clear();
            var status = _repo.RetrieveStatus(new StatusOptions());
            foreach (var entry in status)
            {
                if (entry.State == FileStatus.Ignored) continue;
                if (entry.State == FileStatus.Unaltered) continue;
                _changedFiles.Add(new FileChange
                {
                    FilePath = entry.FilePath,
                    FileName = Path.GetFileName(entry.FilePath),
                    State = entry.State,
                    StatusIcon = GetStatusIcon(entry.State)
                });
            }
            FileCountText.Text = $"{_changedFiles.Count} changed file{(_changedFiles.Count != 1 ? "s" : "")}";
        }

        private string GetStatusIcon(FileStatus state)
        {
            if (state.HasFlag(FileStatus.NewInWorkdir) || state.HasFlag(FileStatus.NewInIndex)) return "🟢";
            if (state.HasFlag(FileStatus.ModifiedInWorkdir) || state.HasFlag(FileStatus.ModifiedInIndex)) return "🟡";
            if (state.HasFlag(FileStatus.DeletedFromWorkdir) || state.HasFlag(FileStatus.DeletedFromIndex)) return "🔴";
            if (state.HasFlag(FileStatus.RenamedInWorkdir) || state.HasFlag(FileStatus.RenamedInIndex)) return "🔵";
            if (state.HasFlag(FileStatus.Conflicted)) return "⚠️";
            return "⚪";
        }

        private void RefreshHistory()
        {
            if (_repo == null) return;
            _history.Clear();
            try
            {
                var commits = _repo.Commits.Take(200);
                foreach (var c in commits)
                {
                    _history.Add(new CommitInfo
                    {
                        Sha = c.Sha,
                        MessageShort = c.MessageShort,
                        AuthorName = c.Author.Name,
                        AuthorEmail = c.Author.Email,
                        When = c.Author.When,
                        TimeAgo = GetTimeAgo(c.Author.When)
                    });
                }
            }
            catch { }
        }

        private void RefreshBranches()
        {
            if (_repo == null) return;
            _branches.Clear();
            BranchCombo.Items.Clear();
            foreach (var b in _repo.Branches.Where(b => !b.IsRemote))
            {
                _branches.Add(new BranchInfo { Name = b.FriendlyName, IsHead = b.IsCurrentRepositoryHead });
                BranchCombo.Items.Add(b.FriendlyName);
                if (b.IsCurrentRepositoryHead)
                    BranchCombo.SelectedItem = b.FriendlyName;
            }
        }

        private void RefreshStashes()
        {
            if (_repo == null) return;
            _stashes.Clear();
            try
            {
                string output = RunGit("stash list");
                foreach (var line in output.Split('\n', StringSplitOptions.RemoveEmptyEntries))
                    _stashes.Add(line.Trim());
            }
            catch { }
        }

        private void RefreshTags()
        {
            if (_repo == null) return;
            _tags.Clear();
            foreach (var t in _repo.Tags)
                _tags.Add(t.FriendlyName);
        }

        private void RefreshRemotes()
        {
            if (_repo == null) return;
            _remotes.Clear();
            foreach (var r in _repo.Network.Remotes)
                _remotes.Add(new RemoteInfo { Name = r.Name, Url = r.Url });
        }

        private void UpdateBranchBar()
        {
            if (_repo == null) return;
            var head = _repo.Head;
            BranchStatusText.Text = $"⑂ {head.FriendlyName}";
            try
            {
                if (head.TrackedBranch != null)
                {
                    var divergence = _repo.ObjectDatabase.CalculateHistoryDivergence(head.Tip, head.TrackedBranch.Tip);
                    int ahead = divergence.AheadBy ?? 0;
                    int behind = divergence.BehindBy ?? 0;
                    AheadBehindText.Text = $"↑{ahead} ↓{behind}";
                }
                else
                {
                    AheadBehindText.Text = "local only";
                }
            }
            catch { AheadBehindText.Text = ""; }
        }

        private string GetTimeAgo(DateTimeOffset when)
        {
            var diff = DateTimeOffset.Now - when;
            if (diff.TotalMinutes < 1) return "just now";
            if (diff.TotalMinutes < 60) return $"{(int)diff.TotalMinutes}m ago";
            if (diff.TotalHours < 24) return $"{(int)diff.TotalHours}h ago";
            if (diff.TotalDays < 30) return $"{(int)diff.TotalDays}d ago";
            if (diff.TotalDays < 365) return $"{(int)(diff.TotalDays / 30)}mo ago";
            return $"{(int)(diff.TotalDays / 365)}y ago";
        }

        // ── Event Handlers ──────────────────────────────────────────

        private void OpenRepo_Click(object sender, RoutedEventArgs e)
        {
            var dlg = new System.Windows.Forms.FolderBrowserDialog
            {
                Description = "Select a Git repository folder",
                ShowNewFolderButton = false
            };
            if (dlg.ShowDialog() == System.Windows.Forms.DialogResult.OK)
            {
                string path = dlg.SelectedPath;
                string repoRoot = Repository.Discover(path) ?? "";
                if (!string.IsNullOrEmpty(repoRoot))
                    OpenRepo(repoRoot);
                else
                    MessageBox.Show("No Git repository found at that location.", "Not a repo");
            }
        }

        internal void CloneRepo_Click(object sender, RoutedEventArgs e)
        {
            var dlg = new CloneDialog();
            if (dlg.ShowDialog() == true && !string.IsNullOrWhiteSpace(dlg.RepoUrl) && !string.IsNullOrWhiteSpace(dlg.TargetPath))
            {
                try
                {
                    SetStatus($"Cloning {dlg.RepoUrl}...");
                    string result = Repository.Clone(dlg.RepoUrl, dlg.TargetPath);
                    OpenRepo(dlg.TargetPath);
                    SetStatus("Clone complete.");
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Clone failed:\n{ex.Message}", "Error");
                    SetStatus("Clone failed.");
                }
            }
        }

        internal void InitRepo_Click(object sender, RoutedEventArgs e)
        {
            var dlg = new System.Windows.Forms.FolderBrowserDialog
            {
                Description = "Select folder to initialize as Git repo",
                ShowNewFolderButton = true
            };
            if (dlg.ShowDialog() == System.Windows.Forms.DialogResult.OK)
            {
                try
                {
                    Repository.Init(dlg.SelectedPath);
                    OpenRepo(dlg.SelectedPath);
                    SetStatus("Repository initialized.");
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Init failed:\n{ex.Message}", "Error");
                }
            }
        }

        private void Fetch_Click(object sender, RoutedEventArgs e)
        {
            if (_repoPath == null) return;
            SetStatus("Fetching...");
            RunGit("fetch --all");
            RefreshAll();
            SetStatus("Fetch complete.");
        }

        private void Pull_Click(object sender, RoutedEventArgs e)
        {
            if (_repoPath == null) return;
            SetStatus("Pulling...");
            string output = RunGit("pull");
            RefreshAll();
            SetStatus(output.Contains("Already up to date") ? "Already up to date." : "Pull complete.");
        }

        private void Push_Click(object sender, RoutedEventArgs e)
        {
            if (_repoPath == null) return;
            SetStatus("Pushing...");
            RunGit("push");
            RefreshAll();
            SetStatus("Push complete.");
        }

        private void Commit_Click(object sender, RoutedEventArgs e)
        {
            if (_repo == null) return;
            string summary = CommitSummary.Text.Trim();
            if (string.IsNullOrEmpty(summary))
            {
                MessageBox.Show("Commit summary is required.", "Missing summary");
                return;
            }

            try
            {
                // Stage all changes
                Commands.Stage(_repo, "*");
                string message = summary;
                if (!string.IsNullOrWhiteSpace(CommitDescription.Text))
                    message += "\n\n" + CommitDescription.Text.Trim();

                var sig = _repo.Config.BuildSignature(DateTimeOffset.Now);
                var options = new CommitOptions();
                if (AmendCheck.IsChecked == true)
                    options.AmendPreviousCommit = true;
                _repo.Commit(message, sig, sig, options);

                CommitSummary.Text = "";
                CommitDescription.Text = "";
                RefreshAll();
                SetStatus($"Committed: {summary}");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Commit failed:\n{ex.Message}", "Error");
            }
        }

        private void BranchCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (_repo == null || BranchCombo.SelectedItem == null) return;
            string name = BranchCombo.SelectedItem.ToString()!;
            var branch = _repo.Branches[name];
            if (branch != null && !branch.IsCurrentRepositoryHead)
            {
                try
                {
                    Commands.Checkout(_repo, branch);
                    RefreshAll();
                    SetStatus($"Switched to {name}");
                }
                catch (Exception ex)
                {
                    SetStatus($"Checkout failed: {ex.Message}");
                }
            }
        }

        private void NewBranch_Click(object sender, RoutedEventArgs e)
        {
            if (_repo == null) return;
            var dlg = new InputDialog("New Branch", "Branch name:");
            if (dlg.ShowDialog() == true && !string.IsNullOrWhiteSpace(dlg.InputText))
            {
                try
                {
                    var branch = _repo.CreateBranch(dlg.InputText);
                    Commands.Checkout(_repo, branch);
                    RefreshAll();
                    SetStatus($"Created and switched to {dlg.InputText}");
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Failed:\n{ex.Message}", "Error");
                }
            }
        }

        private void BranchList_DoubleClick(object sender, System.Windows.Input.MouseButtonEventArgs e)
        {
            if (_repo == null || BranchList.SelectedItem is not BranchInfo bi) return;
            try
            {
                var branch = _repo.Branches[bi.Name];
                if (branch != null)
                {
                    Commands.Checkout(_repo, branch);
                    RefreshAll();
                    SetStatus($"Switched to {bi.Name}");
                }
            }
            catch (Exception ex) { SetStatus($"Checkout failed: {ex.Message}"); }
        }

        private void ChangedFilesList_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (_repo == null || ChangedFilesList.SelectedItem is not FileChange fc) return;
            ShowDiff(fc);
        }

        private void ShowDiff(FileChange fc)
        {
            DiffFileHeader.Text = fc.FilePath;
            var doc = new FlowDocument
            {
                Background = (SolidColorBrush)FindResource("BgDarkBrush"),
                Foreground = (SolidColorBrush)FindResource("TextPrimaryBrush"),
                FontFamily = new FontFamily("Cascadia Code,Consolas,Courier New"),
                FontSize = 13,
                PagePadding = new Thickness(0)
            };

            try
            {
                string diffText = RunGit($"diff -- \"{fc.FilePath}\"");
                if (string.IsNullOrWhiteSpace(diffText))
                    diffText = RunGit($"diff --cached -- \"{fc.FilePath}\"");
                if (string.IsNullOrWhiteSpace(diffText))
                {
                    // New untracked file — show content
                    string fullPath = Path.Combine(_repoPath!, fc.FilePath);
                    if (File.Exists(fullPath))
                        diffText = "+ " + string.Join("\n+ ", File.ReadAllLines(fullPath));
                    else
                        diffText = "(file not found)";
                }

                foreach (var line in diffText.Split('\n'))
                {
                    var para = new Paragraph { Margin = new Thickness(0), Padding = new Thickness(4, 1, 4, 1) };

                    if (line.StartsWith('+') && !line.StartsWith("+++"))
                    {
                        para.Background = new SolidColorBrush(Color.FromArgb(30, 63, 185, 80));
                        para.Foreground = (SolidColorBrush)FindResource("AccentGreenBrush");
                    }
                    else if (line.StartsWith('-') && !line.StartsWith("---"))
                    {
                        para.Background = new SolidColorBrush(Color.FromArgb(30, 248, 81, 73));
                        para.Foreground = (SolidColorBrush)FindResource("AccentRedBrush");
                    }
                    else if (line.StartsWith("@@"))
                    {
                        para.Foreground = (SolidColorBrush)FindResource("AccentPurpleBrush");
                    }
                    else
                    {
                        para.Foreground = (SolidColorBrush)FindResource("TextSecondaryBrush");
                    }

                    para.Inlines.Add(new Run(line));
                    doc.Blocks.Add(para);
                }
            }
            catch (Exception ex)
            {
                doc.Blocks.Add(new Paragraph(new Run($"Error: {ex.Message}"))
                {
                    Foreground = (SolidColorBrush)FindResource("AccentRedBrush")
                });
            }

            DiffView.Document = doc;
        }

        private void HistoryList_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (_repo == null || HistoryList.SelectedItem is not CommitInfo ci) return;
            ShowCommitDiff(ci);
        }

        private void ShowCommitDiff(CommitInfo ci)
        {
            DiffFileHeader.Text = $"{ci.Sha[..8]} — {ci.MessageShort}";
            string diffText = RunGit($"show --stat --format=\"Author: %an <%ae>%nDate: %ai%n%n%B\" {ci.Sha}");

            var doc = new FlowDocument
            {
                Background = (SolidColorBrush)FindResource("BgDarkBrush"),
                FontFamily = new FontFamily("Cascadia Code,Consolas,Courier New"),
                FontSize = 13,
                PagePadding = new Thickness(0)
            };

            foreach (var line in diffText.Split('\n'))
            {
                var para = new Paragraph { Margin = new Thickness(0), Padding = new Thickness(4, 1, 4, 1) };
                if (line.Contains("insertion") || line.Contains("deletion"))
                    para.Foreground = (SolidColorBrush)FindResource("AccentGreenBrush");
                else if (line.StartsWith("Author:"))
                    para.Foreground = (SolidColorBrush)FindResource("AccentBlueBrush");
                else
                    para.Foreground = (SolidColorBrush)FindResource("TextPrimaryBrush");
                para.Inlines.Add(new Run(line));
                doc.Blocks.Add(para);
            }
            DiffView.Document = doc;
        }

        private void StageFile_Click(object sender, RoutedEventArgs e)
        {
            if (_repo == null || ChangedFilesList.SelectedItem is not FileChange fc) return;
            Commands.Stage(_repo, fc.FilePath);
            RefreshChanges();
            SetStatus($"Staged: {fc.FileName}");
        }

        private void DiscardChanges_Click(object sender, RoutedEventArgs e)
        {
            if (_repo == null || ChangedFilesList.SelectedItem is not FileChange fc) return;
            var result = MessageBox.Show($"Discard all changes to {fc.FileName}?", "Confirm Discard",
                MessageBoxButton.YesNo, MessageBoxImage.Warning);
            if (result == MessageBoxResult.Yes)
            {
                RunGit($"checkout -- \"{fc.FilePath}\"");
                RefreshChanges();
                SetStatus($"Discarded: {fc.FileName}");
            }
        }

        private void StashSave_Click(object sender, RoutedEventArgs e)
        {
            if (_repoPath == null) return;
            RunGit("stash push -m \"GitDesk stash\"");
            RefreshAll();
            SetStatus("Changes stashed.");
        }

        private void StashPop_Click(object sender, RoutedEventArgs e)
        {
            if (_repoPath == null) return;
            RunGit("stash pop");
            RefreshAll();
            SetStatus("Stash popped.");
        }

        private void Merge_Click(object sender, RoutedEventArgs e)
        {
            if (_repo == null) return;
            var branchNames = _repo.Branches.Where(b => !b.IsRemote).Select(b => b.FriendlyName);
            var dlg = new MergeDialog(_repo.Head.FriendlyName, branchNames);
            if (dlg.ShowDialog() == true && dlg.SelectedBranch != null)
            {
                try
                {
                    SetStatus($"Merging {dlg.SelectedBranch}...");
                    if (dlg.Squash)
                    {
                        RunGit($"merge --squash {dlg.SelectedBranch}");
                    }
                    else
                    {
                        var branch = _repo.Branches[dlg.SelectedBranch];
                        if (branch != null)
                        {
                            var sig = _repo.Config.BuildSignature(DateTimeOffset.Now);
                            _repo.Merge(branch, sig);
                        }
                    }
                    RefreshAll();
                    SetStatus($"Merged {dlg.SelectedBranch} into {_repo.Head.FriendlyName}");
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Merge failed:\n{ex.Message}", "Error");
                    SetStatus("Merge failed.");
                }
            }
        }

        private void NewTag_Click(object sender, RoutedEventArgs e)
        {
            if (_repo == null) return;
            var dlg = new InputDialog("New Tag", "Tag name:");
            if (dlg.ShowDialog() == true && !string.IsNullOrWhiteSpace(dlg.InputText))
            {
                try
                {
                    _repo.ApplyTag(dlg.InputText);
                    RefreshTags();
                    SetStatus($"Tag created: {dlg.InputText}");
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Failed:\n{ex.Message}", "Error");
                }
            }
        }

        private void AddRemote_Click(object sender, RoutedEventArgs e)
        {
            if (_repo == null) return;
            var nameDlg = new InputDialog("Add Remote", "Remote name (e.g. origin):");
            if (nameDlg.ShowDialog() == true && !string.IsNullOrWhiteSpace(nameDlg.InputText))
            {
                var urlDlg = new InputDialog("Add Remote", "Remote URL:");
                if (urlDlg.ShowDialog() == true && !string.IsNullOrWhiteSpace(urlDlg.InputText))
                {
                    try
                    {
                        _repo.Network.Remotes.Add(nameDlg.InputText, urlDlg.InputText);
                        RefreshRemotes();
                        SetStatus($"Remote added: {nameDlg.InputText}");
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Failed:\n{ex.Message}", "Error");
                    }
                }
            }
        }

        private void BranchCheckout_Click(object sender, RoutedEventArgs e)
        {
            if (_repo == null || BranchList.SelectedItem is not BranchInfo bi) return;
            try
            {
                var branch = _repo.Branches[bi.Name];
                if (branch != null) { Commands.Checkout(_repo, branch); RefreshAll(); SetStatus($"Switched to {bi.Name}"); }
            }
            catch (Exception ex) { SetStatus($"Failed: {ex.Message}"); }
        }

        private void BranchRename_Click(object sender, RoutedEventArgs e)
        {
            if (_repo == null || BranchList.SelectedItem is not BranchInfo bi) return;
            var dlg = new InputDialog("Rename Branch", $"New name for '{bi.Name}':");
            if (dlg.ShowDialog() == true && !string.IsNullOrWhiteSpace(dlg.InputText))
            {
                RunGit($"branch -m {bi.Name} {dlg.InputText}");
                RefreshAll();
                SetStatus($"Renamed {bi.Name} to {dlg.InputText}");
            }
        }

        private void BranchDelete_Click(object sender, RoutedEventArgs e)
        {
            if (_repo == null || BranchList.SelectedItem is not BranchInfo bi) return;
            if (bi.IsHead) { MessageBox.Show("Cannot delete the current branch.", "Error"); return; }
            var result = MessageBox.Show($"Delete branch '{bi.Name}'?", "Delete Branch",
                MessageBoxButton.YesNo, MessageBoxImage.Warning);
            if (result == MessageBoxResult.Yes)
            {
                try
                {
                    _repo.Branches.Remove(bi.Name);
                    RefreshAll();
                    SetStatus($"Deleted branch: {bi.Name}");
                }
                catch (Exception ex) { MessageBox.Show($"Failed:\n{ex.Message}", "Error"); }
            }
        }

        private void OpenInExplorer_Click(object sender, RoutedEventArgs e)
        {
            if (_repoPath == null) return;
            Process.Start("explorer.exe", _repoPath);
        }

        private void OpenTerminal_Click(object sender, RoutedEventArgs e)
        {
            if (_repoPath == null) return;
            Process.Start(new ProcessStartInfo("wt", $"-d \"{_repoPath}\"") { UseShellExecute = true });
        }

        private void BlameFile_Click(object sender, RoutedEventArgs e)
        {
            if (_repo == null || ChangedFilesList.SelectedItem is not FileChange fc) return;
            string blameText = RunGit($"blame -- \"{fc.FilePath}\"");
            ShowTextInDiff($"Blame: {fc.FilePath}", blameText, Brushes.CornflowerBlue);
        }

        private void OpenFileInExplorer_Click(object sender, RoutedEventArgs e)
        {
            if (_repoPath == null || ChangedFilesList.SelectedItem is not FileChange fc) return;
            string fullPath = Path.Combine(_repoPath, fc.FilePath);
            if (File.Exists(fullPath))
                Process.Start("explorer.exe", $"/select,\"{fullPath}\"");
        }

        private void CherryPick_Click(object sender, RoutedEventArgs e)
        {
            if (_repo == null || HistoryList.SelectedItem is not CommitInfo ci) return;
            var result = MessageBox.Show($"Cherry-pick commit {ci.Sha[..8]}?\n{ci.MessageShort}", "Cherry-pick",
                MessageBoxButton.YesNo, MessageBoxImage.Question);
            if (result == MessageBoxResult.Yes)
            {
                try
                {
                    var commit = _repo.Lookup<Commit>(ci.Sha);
                    if (commit != null)
                    {
                        _repo.CherryPick(commit, commit.Author);
                        RefreshAll();
                        SetStatus($"Cherry-picked: {ci.MessageShort}");
                    }
                }
                catch (Exception ex) { MessageBox.Show($"Failed:\n{ex.Message}", "Error"); }
            }
        }

        private void Revert_Click(object sender, RoutedEventArgs e)
        {
            if (_repo == null || HistoryList.SelectedItem is not CommitInfo ci) return;
            var result = MessageBox.Show($"Revert commit {ci.Sha[..8]}?\n{ci.MessageShort}", "Revert",
                MessageBoxButton.YesNo, MessageBoxImage.Question);
            if (result == MessageBoxResult.Yes)
            {
                try
                {
                    var commit = _repo.Lookup<Commit>(ci.Sha);
                    if (commit != null)
                    {
                        _repo.Revert(commit, commit.Author);
                        RefreshAll();
                        SetStatus($"Reverted: {ci.MessageShort}");
                    }
                }
                catch (Exception ex) { MessageBox.Show($"Failed:\n{ex.Message}", "Error"); }
            }
        }

        private void CopySha_Click(object sender, RoutedEventArgs e)
        {
            if (HistoryList.SelectedItem is not CommitInfo ci) return;
            Clipboard.SetText(ci.Sha);
            SetStatus($"Copied: {ci.Sha}");
        }

        private void ShowTextInDiff(string header, string text, Brush defaultColor)
        {
            DiffFileHeader.Text = header;
            var doc = new FlowDocument
            {
                Background = (SolidColorBrush)FindResource("BgDarkBrush"),
                FontFamily = new FontFamily("Cascadia Code,Consolas,Courier New"),
                FontSize = 13,
                PagePadding = new Thickness(0)
            };
            foreach (var line in text.Split('\n'))
            {
                var para = new Paragraph(new Run(line))
                {
                    Margin = new Thickness(0),
                    Padding = new Thickness(4, 1, 4, 1),
                    Foreground = defaultColor
                };
                doc.Blocks.Add(para);
            }
            DiffView.Document = doc;
        }

        private void SearchBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            // Filter changed files by search text
            if (_repo == null) return;
            string query = SearchBox.Text.Trim().ToLower();
            if (string.IsNullOrEmpty(query))
            {
                RefreshChanges();
                return;
            }
            // Simple filter on existing items
            var filtered = _changedFiles.Where(f => f.FilePath.ToLower().Contains(query)).ToList();
            ChangedFilesList.ItemsSource = filtered;
        }

        private void SetupFileWatcher(string repoPath)
        {
            _watcher?.Dispose();
            _refreshTimer?.Stop();

            _refreshTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(500) };
            _refreshTimer.Tick += (s, e) =>
            {
                _refreshTimer.Stop();
                try { RefreshChanges(); } catch { }
            };

            try
            {
                _watcher = new FileSystemWatcher(repoPath)
                {
                    IncludeSubdirectories = true,
                    NotifyFilter = NotifyFilters.FileName | NotifyFilters.LastWrite | NotifyFilters.DirectoryName,
                    EnableRaisingEvents = true
                };
                _watcher.Changed += (s, e) => { if (!e.FullPath.Contains(".git")) Dispatcher.Invoke(() => _refreshTimer.Start()); };
                _watcher.Created += (s, e) => { if (!e.FullPath.Contains(".git")) Dispatcher.Invoke(() => _refreshTimer.Start()); };
                _watcher.Deleted += (s, e) => { if (!e.FullPath.Contains(".git")) Dispatcher.Invoke(() => _refreshTimer.Start()); };
                _watcher.Renamed += (s, e) => { if (!e.FullPath.Contains(".git")) Dispatcher.Invoke(() => _refreshTimer.Start()); };
            }
            catch { }
        }

        protected override void OnClosed(EventArgs e)
        {
            _watcher?.Dispose();
            _refreshTimer?.Stop();
            _repo?.Dispose();
            base.OnClosed(e);
        }
    }

    // ── Models ──────────────────────────────────────────────────

    public class FileChange
    {
        public string FilePath { get; set; } = "";
        public string FileName { get; set; } = "";
        public FileStatus State { get; set; }
        public string StatusIcon { get; set; } = "⚪";
    }

    public class CommitInfo
    {
        public string Sha { get; set; } = "";
        public string MessageShort { get; set; } = "";
        public string AuthorName { get; set; } = "";
        public string AuthorEmail { get; set; } = "";
        public DateTimeOffset When { get; set; }
        public string TimeAgo { get; set; } = "";
    }

    public class BranchInfo
    {
        public string Name { get; set; } = "";
        public bool IsHead { get; set; }
    }

    public class RemoteInfo
    {
        public string Name { get; set; } = "";
        public string Url { get; set; } = "";
    }

    public class RelayCommand : System.Windows.Input.ICommand
    {
        private readonly Action<object?> _execute;
        public RelayCommand(Action<object?> execute) { _execute = execute; }
        public event EventHandler? CanExecuteChanged;
        public bool CanExecute(object? parameter) => true;
        public void Execute(object? parameter) => _execute(parameter);
    }
}
