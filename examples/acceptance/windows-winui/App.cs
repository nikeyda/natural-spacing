using Microsoft.UI.Xaml;

namespace NaturalSpacing.WinUI.Acceptance;

public sealed class App : Application
{
    private Window? _window;

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        _window = new MainWindow();
        _window.Activate();
    }
}
