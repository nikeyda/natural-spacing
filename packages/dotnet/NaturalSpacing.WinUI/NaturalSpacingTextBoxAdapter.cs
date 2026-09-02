using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace NaturalSpacing.WinUI;

/// <summary>
/// Experimental settled-input adapter for a plain-text WinUI 3 <see cref="TextBox"/>.
/// </summary>
public sealed class NaturalSpacingTextBoxAdapter : IDisposable
{
    private readonly TextBox _textBox;
    private readonly NaturalSpacing.Core.NaturalSpacingObservedTextSession _observedText;
    private NaturalSpacing.Core.FieldPolicy _policy;
    private bool _isComposing;
    private bool _isApplying;
    private bool _isScheduled;
    private bool _isDisposed;

    public NaturalSpacingTextBoxAdapter(
        TextBox textBox,
        NaturalSpacing.Core.FieldPolicy policy = NaturalSpacing.Core.FieldPolicy.Verbatim)
    {
        ArgumentNullException.ThrowIfNull(textBox);
        _textBox = textBox;
        _policy = policy;
        _observedText = new NaturalSpacing.Core.NaturalSpacingObservedTextSession(
            textBox.Text ?? string.Empty);
        _textBox.TextChanged += OnTextChanged;
        _textBox.TextCompositionStarted += OnTextCompositionStarted;
        _textBox.TextCompositionEnded += OnTextCompositionEnded;
    }

    public NaturalSpacing.Core.FieldPolicy Policy
    {
        get => _policy;
        set
        {
            ObjectDisposedException.ThrowIf(_isDisposed, this);
            if (_policy == value) return;
            _policy = value;
            Sync();
        }
    }

    /// <summary>The last settled coordinator plan, cleared by <see cref="Sync"/>.</summary>
    public NaturalSpacing.Core.EditPlan? LastPlan { get; private set; }

    /// <summary>
    /// Resets deletion-intent state and adopts the control's current text as the settled baseline.
    /// Call this after an external model replaces the field value intentionally.
    /// </summary>
    public void Sync()
    {
        ObjectDisposedException.ThrowIf(_isDisposed, this);
        _observedText.Sync(_textBox.Text ?? string.Empty);
        LastPlan = null;
    }

    public void Dispose()
    {
        if (_isDisposed) return;
        _isDisposed = true;
        _textBox.TextChanged -= OnTextChanged;
        _textBox.TextCompositionStarted -= OnTextCompositionStarted;
        _textBox.TextCompositionEnded -= OnTextCompositionEnded;
    }

    private void OnTextCompositionStarted(TextBox sender, TextCompositionStartedEventArgs args) =>
        _isComposing = true;

    private void OnTextCompositionEnded(TextBox sender, TextCompositionEndedEventArgs args)
    {
        _isComposing = false;
        ScheduleReconciliation();
    }

    private void OnTextChanged(object sender, TextChangedEventArgs args)
    {
        if (!_isApplying && !_isComposing) ScheduleReconciliation();
    }

    private void ScheduleReconciliation()
    {
        if (_isDisposed || _isApplying || _isComposing || _isScheduled) return;
        _isScheduled = true;
        if (!_textBox.DispatcherQueue.TryEnqueue(
                DispatcherQueuePriority.Normal,
                () =>
                {
                    _isScheduled = false;
                    ReconcileSettledText();
                }))
        {
            _isScheduled = false;
        }
    }

    private void ReconcileSettledText()
    {
        if (_isDisposed || _isApplying || _isComposing) return;
        var currentText = _textBox.Text ?? string.Empty;

        var selectionStart = _textBox.SelectionStart;
        var selection = new NaturalSpacing.Core.TextSelection(
            selectionStart,
            selectionStart + _textBox.SelectionLength);
        int? maxLength = _textBox.MaxLength > 0 ? _textBox.MaxLength : null;
        var result = _observedText.Reconcile(
            currentText,
            _policy,
            selection,
            maxLength);
        LastPlan = result?.Plan;
        if (result?.RequiresReplacement == true)
            ApplyMinimalReplacement(currentText, result.Plan);
    }

    private void ApplyMinimalReplacement(string currentText, NaturalSpacing.Core.EditPlan plan)
    {
        var replacement = NaturalSpacing.Core.NaturalSpacingFormatter.ReplacingDifference(
            currentText,
            plan.ResultText,
            NaturalSpacing.Core.FieldPolicy.Verbatim);
        if (replacement is null)
        {
            _observedText.Sync(_textBox.Text ?? string.Empty);
            return;
        }

        _isApplying = true;
        try
        {
            _textBox.Select(replacement.Range.Start, replacement.Range.Length);
            _textBox.SelectedText = replacement.ReplacementText;
            var start = Math.Min(plan.Selection.Anchor, plan.Selection.Focus);
            var length = Math.Abs(plan.Selection.Focus - plan.Selection.Anchor);
            _textBox.Select(start, length);
        }
        catch
        {
            _observedText.Sync(_textBox.Text ?? string.Empty);
            throw;
        }
        finally
        {
            _isApplying = false;
        }

        if (!string.Equals(_textBox.Text, plan.ResultText, StringComparison.Ordinal))
            _observedText.Sync(_textBox.Text ?? string.Empty);
    }
}
