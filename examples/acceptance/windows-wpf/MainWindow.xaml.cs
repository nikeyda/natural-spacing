using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Threading;
using NaturalSpacing.Core;

namespace NaturalSpacing.Wpf.Acceptance;

public partial class MainWindow : Window
{
    private NaturalSpacing.Wpf.NaturalSpacingTextBoxAdapter? _messageAdapter;
    private NaturalSpacing.Wpf.NaturalSpacingTextBoxAdapter? _verbatimAdapter;
    private bool _messageIsComposing;

    public MainWindow() => InitializeComponent();

    private void Window_Loaded(object sender, RoutedEventArgs e)
    {
        var messagePolicy = NaturalSpacingPolicy.Resolve(
            new PolicyContext(ContentKind: ContentKind.Message));
        var verbatimPolicy = NaturalSpacingPolicy.Resolve(
            new PolicyContext(ContentKind: ContentKind.Password, IsSecure: true));
        if (messagePolicy != FieldPolicy.NaturalLanguage || verbatimPolicy != FieldPolicy.Verbatim)
            throw new InvalidOperationException("Acceptance policies did not resolve safely.");

        _messageAdapter = new NaturalSpacing.Wpf.NaturalSpacingTextBoxAdapter(
            MessageEditor,
            messagePolicy);
        _verbatimAdapter = new NaturalSpacing.Wpf.NaturalSpacingTextBoxAdapter(
            VerbatimEditor,
            verbatimPolicy);

        TextCompositionManager.AddPreviewTextInputStartHandler(
            MessageEditor,
            MessageCompositionStarted);
        TextCompositionManager.AddPreviewTextInputHandler(
            MessageEditor,
            MessageCompositionCompleted);

        UpdateStatus();
        MessageEditor.Focus();
    }

    private void Window_Closed(object? sender, EventArgs e)
    {
        TextCompositionManager.RemovePreviewTextInputStartHandler(
            MessageEditor,
            MessageCompositionStarted);
        TextCompositionManager.RemovePreviewTextInputHandler(
            MessageEditor,
            MessageCompositionCompleted);
        _messageAdapter?.Dispose();
        _verbatimAdapter?.Dispose();
    }

    private void MessageCompositionStarted(object sender, TextCompositionEventArgs e)
    {
        _messageIsComposing = true;
        ScheduleStatusUpdate();
    }

    private void MessageCompositionCompleted(object sender, TextCompositionEventArgs e)
    {
        _messageIsComposing = false;
        ScheduleStatusUpdate();
    }

    private void Editor_TextChanged(object sender, TextChangedEventArgs e) =>
        ScheduleStatusUpdate();

    private void Editor_SelectionChanged(object sender, RoutedEventArgs e) =>
        ScheduleStatusUpdate();

    private void Reset_Click(object sender, RoutedEventArgs e)
    {
        MessageEditor.Clear();
        VerbatimEditor.Clear();
        _messageAdapter?.Sync();
        _verbatimAdapter?.Sync();
        _messageIsComposing = false;
        MessageEditor.Focus();
        UpdateStatus();
    }

    private void ScheduleStatusUpdate() => Dispatcher.BeginInvoke(
        DispatcherPriority.ContextIdle,
        new Action(UpdateStatus));

    private void UpdateStatus()
    {
        MessageStatus.Text =
            $"policy=NATURAL_LANGUAGE  composing={_messageIsComposing}  " +
            $"selection={MessageEditor.SelectionStart}:{MessageEditor.SelectionLength}  " +
            $"decision={_messageAdapter?.LastPlan?.Decision.ToString() ?? "none"}\n" +
            $"text={MessageEditor.Text}";
        VerbatimStatus.Text =
            $"policy=VERBATIM  selection={VerbatimEditor.SelectionStart}:{VerbatimEditor.SelectionLength}  " +
            $"decision={_verbatimAdapter?.LastPlan?.Decision.ToString() ?? "none"}\n" +
            $"text={VerbatimEditor.Text}";
    }
}
