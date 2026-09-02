using Microsoft.UI.Dispatching;
using Microsoft.UI.Text;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using NaturalSpacing.Core;

namespace NaturalSpacing.WinUI.Acceptance;

public sealed class MainWindow : Window
{
    private readonly TextBox _messageEditor;
    private readonly TextBox _verbatimEditor;
    private readonly TextBlock _messageStatus;
    private readonly TextBlock _verbatimStatus;
    private readonly global::NaturalSpacing.WinUI.NaturalSpacingTextBoxAdapter _messageAdapter;
    private readonly global::NaturalSpacing.WinUI.NaturalSpacingTextBoxAdapter _verbatimAdapter;
    private bool _messageIsComposing;

    public MainWindow()
    {
        Title = "Natural Spacing WinUI Acceptance";

        var messagePolicy = NaturalSpacingPolicy.Resolve(
            new PolicyContext(ContentKind: ContentKind.Message));
        var verbatimPolicy = NaturalSpacingPolicy.Resolve(
            new PolicyContext(ContentKind: ContentKind.Password, IsSecure: true));
        if (messagePolicy != FieldPolicy.NaturalLanguage || verbatimPolicy != FieldPolicy.Verbatim)
            throw new InvalidOperationException("Acceptance policies did not resolve safely.");

        _messageEditor = new TextBox
        {
            Header = "Natural-language message",
            PlaceholderText = "Try synthetic text: 中A, A中, 中2, or 2中",
            AcceptsReturn = true,
            MinHeight = 160,
            FontSize = 24,
            IsSpellCheckEnabled = false,
            TextWrapping = TextWrapping.Wrap,
        };
        AutomationProperties.SetName(_messageEditor, "Natural language acceptance editor");

        _verbatimEditor = new TextBox
        {
            Header = "Verbatim structured field",
            PlaceholderText = "Try synthetic structured content: https://example.test/v2",
            MinHeight = 52,
            FontSize = 20,
            IsSpellCheckEnabled = false,
        };
        AutomationProperties.SetName(_verbatimEditor, "Verbatim acceptance editor");

        _messageStatus = StatusText("Message editor status");
        _verbatimStatus = StatusText("Verbatim editor status");
        var resetButton = new Button
        {
            Content = "Reset synthetic text",
            Width = 190,
            HorizontalAlignment = HorizontalAlignment.Left,
            Padding = new Thickness(12, 8, 12, 8),
        };
        AutomationProperties.SetName(resetButton, "Reset both acceptance editors");
        resetButton.Click += ResetClicked;

        var stack = new StackPanel { Spacing = 12 };
        stack.Children.Add(new TextBlock
        {
            Text = "Natural Spacing WinUI Acceptance",
            FontSize = 26,
            FontWeight = FontWeights.SemiBold,
        });
        stack.Children.Add(new TextBlock
        {
            Text = "Use only synthetic text. Record Windows, hardware or VM, the exact IME/input source, adapter revision, and each attempted scenario. Active composition must remain untouched.",
            TextWrapping = TextWrapping.Wrap,
            Margin = new Thickness(0, 0, 0, 8),
        });
        stack.Children.Add(_messageEditor);
        stack.Children.Add(_messageStatus);
        stack.Children.Add(_verbatimEditor);
        stack.Children.Add(_verbatimStatus);
        stack.Children.Add(resetButton);

        Content = new ScrollViewer
        {
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Content = new Border
            {
                Padding = new Thickness(28),
                Child = stack,
            },
        };

        _messageAdapter = new global::NaturalSpacing.WinUI.NaturalSpacingTextBoxAdapter(
            _messageEditor,
            messagePolicy);
        _verbatimAdapter = new global::NaturalSpacing.WinUI.NaturalSpacingTextBoxAdapter(
            _verbatimEditor,
            verbatimPolicy);

        _messageEditor.TextCompositionStarted += MessageCompositionStarted;
        _messageEditor.TextCompositionEnded += MessageCompositionEnded;
        _messageEditor.TextChanged += EditorTextChanged;
        _messageEditor.SelectionChanged += EditorSelectionChanged;
        _verbatimEditor.TextChanged += EditorTextChanged;
        _verbatimEditor.SelectionChanged += EditorSelectionChanged;
        Closed += WindowClosed;

        UpdateStatus();
        _messageEditor.Focus(FocusState.Programmatic);
    }

    private static TextBlock StatusText(string accessibleName)
    {
        var status = new TextBlock
        {
            FontFamily = new FontFamily("Consolas"),
            FontSize = 13,
            TextWrapping = TextWrapping.Wrap,
            Margin = new Thickness(0, 0, 0, 8),
        };
        AutomationProperties.SetName(status, accessibleName);
        return status;
    }

    private void MessageCompositionStarted(
        TextBox sender,
        TextCompositionStartedEventArgs args)
    {
        _messageIsComposing = true;
        ScheduleStatusUpdate();
    }

    private void MessageCompositionEnded(
        TextBox sender,
        TextCompositionEndedEventArgs args)
    {
        _messageIsComposing = false;
        ScheduleStatusUpdate();
    }

    private void EditorTextChanged(object sender, TextChangedEventArgs args) =>
        ScheduleStatusUpdate();

    private void EditorSelectionChanged(object sender, RoutedEventArgs args) =>
        ScheduleStatusUpdate();

    private void ResetClicked(object sender, RoutedEventArgs args)
    {
        _messageEditor.Text = string.Empty;
        _verbatimEditor.Text = string.Empty;
        _messageAdapter.Sync();
        _verbatimAdapter.Sync();
        _messageIsComposing = false;
        _messageEditor.Focus(FocusState.Programmatic);
        UpdateStatus();
    }

    private void WindowClosed(object sender, WindowEventArgs args)
    {
        _messageAdapter.Dispose();
        _verbatimAdapter.Dispose();
    }

    private void ScheduleStatusUpdate() => DispatcherQueue.TryEnqueue(
        DispatcherQueuePriority.Low,
        UpdateStatus);

    private void UpdateStatus()
    {
        _messageStatus.Text =
            $"policy=NATURAL_LANGUAGE  composing={_messageIsComposing}  " +
            $"selection={_messageEditor.SelectionStart}:{_messageEditor.SelectionLength}  " +
            $"decision={_messageAdapter.LastPlan?.Decision.ToString() ?? "none"}\n" +
            $"text={_messageEditor.Text}";
        _verbatimStatus.Text =
            $"policy=VERBATIM  selection={_verbatimEditor.SelectionStart}:{_verbatimEditor.SelectionLength}  " +
            $"decision={_verbatimAdapter.LastPlan?.Decision.ToString() ?? "none"}\n" +
            $"text={_verbatimEditor.Text}";
    }
}
