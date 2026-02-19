using System.Windows;

namespace GitDesk
{
    public partial class InputDialog : Window
    {
        public string InputText => InputBox.Text.Trim();

        public InputDialog(string title, string prompt)
        {
            InitializeComponent();
            Owner = Application.Current.MainWindow;
            TitleText.Text = title;
            PromptText.Text = prompt;
            Title = title;
            InputBox.Focus();
        }

        private void OK_Click(object sender, RoutedEventArgs e)
        {
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
