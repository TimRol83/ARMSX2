import os
import SwiftUI

#if os(iOS)
@available(iOS, deprecated: 16.0)
public struct NavigationStack<Root: View>: View {
    let root: Root
    public init(@ViewBuilder root: () -> Root) { self.root = root() }
    public init(path: Any? = nil, @ViewBuilder root: () -> Root) { self.root = root() }
    public init<P>(path: Binding<P>, @ViewBuilder root: () -> Root) { self.root = root() }
    public var body: some View {
        NavigationView { root }.navigationViewStyle(.stack)
    }
}

@available(iOS, deprecated: 16.0)
public struct NavigationSplitView<Sidebar: View, Detail: View>: View {
    let sidebar: Sidebar
    let detail: Detail
    public init(@ViewBuilder sidebar: () -> Sidebar, @ViewBuilder detail: () -> Detail) {
        self.sidebar = sidebar()
        self.detail = detail()
    }
    public var body: some View {
        NavigationView {
            sidebar
            detail
        }
    }
}

@available(iOS, deprecated: 17.0)
public struct ContentUnavailableView<Label: View, Description: View, Actions: View>: View {
    let label: Label
    let description: Description
    let actions: Actions
    public init(@ViewBuilder label: () -> Label,
                @ViewBuilder description: () -> Description = { EmptyView() },
                @ViewBuilder actions: () -> Actions = { EmptyView() }) {
        self.label = label()
        self.description = description()
        self.actions = actions()
    }
    public var body: some View {
        VStack(spacing: 10) {
            label.font(.headline)
            description.font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            actions
        }
        .padding()
    }
}

public extension ContentUnavailableView where Label == SwiftUI.Label<Text, Image>, Description == Text?, Actions == EmptyView {
    init(_ title: LocalizedStringKey, systemImage: String, description: Text? = nil) {
        self.label = SwiftUI.Label(title, systemImage: systemImage)
        self.description = description
        self.actions = EmptyView()
    }
    init<S: StringProtocol>(_ title: S, systemImage: String, description: Text? = nil) {
        self.label = SwiftUI.Label(title, systemImage: systemImage)
        self.description = description
        self.actions = EmptyView()
    }
}

@available(iOS, deprecated: 16.0)
public struct LabeledContent<Label: View, Content: View>: View {
    let label: Label
    let content: Content
    public init(@ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {
        self.content = content()
        self.label = label()
    }
    public init(_ titleKey: LocalizedStringKey, @ViewBuilder content: () -> Content) where Label == Text {
        self.label = Text(titleKey)
        self.content = content()
    }
    public init<S: StringProtocol>(_ title: S, @ViewBuilder content: () -> Content) where Label == Text {
        self.label = Text(title)
        self.content = content()
    }
    public var body: some View {
        HStack {
            label
            Spacer()
            content.foregroundColor(.secondary)
        }
    }
}

public enum PresentationDetent: Hashable {
    case medium, large
    case fraction(CGFloat)
    case height(CGFloat)
}

public enum Visibility {
    case automatic, visible, hidden
}

public extension View {
    func presentationDetents(_ detents: Set<PresentationDetent>) -> some View { self }
    func presentationDragIndicator(_ visibility: Visibility) -> some View { self }
    func scrollContentBackground(_ visibility: Visibility) -> some View { self }
    func toolbarBackground(_ visibility: Visibility, for bars: Any...) -> some View { self }
}

public extension View {
    func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        _ action: @escaping (_ oldValue: V, _ newValue: V) -> Void
    ) -> some View {
        self.modifier(OnChangeTwoArgModifier(value: value, initial: initial, action: action))
    }
}

private struct OnChangeTwoArgModifier<V: Equatable>: ViewModifier {
    let value: V
    let initial: Bool
    let action: (V, V) -> Void
    @State private var oldValue: V
    @State private var didAppear = false

    init(value: V, initial: Bool, action: @escaping (V, V) -> Void) {
        self.value = value
        self.initial = initial
        self.action = action
        _oldValue = State(initialValue: value)
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                if initial && !didAppear {
                    didAppear = true
                    action(value, value)
                }
            }
            .onChange(of: value) { newValue in
                let prev = oldValue
                oldValue = newValue
                action(prev, newValue)
            }
    }
}


@available(iOS, deprecated: 17.0)
public struct Duration: Sendable, Hashable {
    public let nanoseconds: UInt64
    public init(nanoseconds: UInt64) { self.nanoseconds = nanoseconds }
    public static func milliseconds<T: BinaryInteger>(_ value: T) -> Duration {
        Duration(nanoseconds: UInt64(max(0, Int64(value))) * 1_000_000)
    }
    public static func seconds<T: BinaryInteger>(_ value: T) -> Duration {
        Duration(nanoseconds: UInt64(max(0, Int64(value))) * 1_000_000_000)
    }
    public static func seconds(_ value: Double) -> Duration {
        Duration(nanoseconds: UInt64(max(0.0, value) * 1_000_000_000.0))
    }
}

public extension Task where Success == Never, Failure == Never {
    static func sleep(for duration: Duration) async throws {
        try await Task.sleep(nanoseconds: duration.nanoseconds)
    }
}
extension View {
    @ViewBuilder
    func focusEffectDisabledCompat(_ disabled: Bool = true) -> some View {
        if #available(iOS 17.0, *) {
            self.focusEffectDisabled(disabled)
        } else {
            self
        }
    }
}
