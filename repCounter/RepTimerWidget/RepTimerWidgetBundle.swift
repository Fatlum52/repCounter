import SwiftUI
import WidgetKit

// The extension exists purely to render the timer's Live Activity; it ships no home
// screen widgets.
@main
struct RepTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimerLiveActivityWidget()
    }
}
