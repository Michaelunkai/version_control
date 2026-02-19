using System.Windows;

namespace GitDesk
{
    public partial class CloneDialog : Window
    {
        public string RepoUrl => UrlBox.Text.Trim();
        public string TargetPath => PathBox.Text.Trim();

        public CloneDialog()
        {
            InitializeComponent();
            Owner = Application.Current.MainWindow;
            PathBox.Text = System.IO.Path.Combine(
                System.Environment.GetFolderPath(System.Environment.SpecialFolder.UserProfile), "Repos");
        }

        private void Browse_Click(object sender, RoutedEventArgs e)
        {
            var dlg = new System.Windows.Forms.FolderBrowserDialog { ShowNewFolderButton = true };
            if (dlg.ShowDialog() == System.Windows.Forms.DialogResult.OK)
                PathBox.Text = dlg.SelectedPath;
        }

        private void Clone_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrWhiteSpace(RepoUrl))
            {
                MessageBox.Show("Please enter a repository URL.", "Missing URL");
                return;
            }
            DialogResult = true;
            Close();
        }

        private void Cancel_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
            Close();
        }
    }
}
