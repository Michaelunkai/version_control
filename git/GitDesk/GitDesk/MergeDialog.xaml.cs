using System.Collections.Generic;
using System.Windows;

namespace GitDesk
{
    public partial class MergeDialog : Window
    {
        public string? SelectedBranch => BranchCombo.SelectedItem?.ToString();
        public bool Squash => SquashCheck.IsChecked == true;

        public MergeDialog(string currentBranch, IEnumerable<string> branches)
        {
            InitializeComponent();
            Owner = Application.Current.MainWindow;
            CurrentBranchText.Text = $"Current branch: {currentBranch}";
            foreach (var b in branches)
            {
                if (b != currentBranch)
                    BranchCombo.Items.Add(b);
            }
            if (BranchCombo.Items.Count > 0)
                BranchCombo.SelectedIndex = 0;
        }

        private void Merge_Click(object sender, RoutedEventArgs e)
        {
            if (BranchCombo.SelectedItem == null)
            {
                MessageBox.Show("Select a branch to merge.", "No branch selected");
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
