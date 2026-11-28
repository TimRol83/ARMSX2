import os
import SwiftUI

#if os(iOS)
@available(iOS, deprecated: 16.0)
public struct NavigationStack<Root: View>: View {
    let root: Root
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
#endif


#if os(iOS)
@available(iOS 15.0, *)
public extension View {
    @ViewBuilder
    func onChangeCompat<V: Equatable>(of value: V, perform action: @escaping (_ oldValue: V, _ newValue: V) -> Void) -> some View {
        self.modifier(OnChangeTwoArgModifier(value: value, initial: false, action: action))
    }
    @ViewBuilder
    func onChangeCompat<V: Equatable>(of value: V, perform action: @escaping (_ newValue: V) -> Void) -> some View {
        self.onChange(of: value, perform: action)
    }
    @ViewBuilder
    func onChangeCompat<V: Equatable>(of value: V, initial: Bool = false, _ action: @escaping (_ oldValue: V, _ newValue: V) -> Void) -> some View {
        self.modifier(OnChangeTwoArgModifier(value: value, initial: false, action: action))
    }
}

@available(iOS 15.0, *)
private struct OnChangeTwoArgModifier<V: Equatable>: ViewModifier {
    let value: V
    let action: (V, V) -> Void
    @State private var prev: V
    init(value: V, action: @escaping (V, V) -> Void) {
        self.value = value
        self.action = action
        _prev = State(initialValue: value)
    }
    func body(content: Content) -> some View {
        content.onChange(of: value) { newVal in
            let oldVal = prev
            prev = newVal
            action(oldVal, newVal)
        }
    }
}

@propertyWrapper
public struct Bindable<Value: AnyObject> {
    public var wrappedValue: Value
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    public init(_ wrappedValue: Value) { self.wrappedValue = wrappedValue }
    public var projectedValue: Wrapper { Wrapper(value: wrappedValue) }
    @dynamicMemberLookup
    public struct Wrapper {
        let value: Value
        public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<Value, Subject>) -> Binding<Subject> {
            Binding(get: { value[keyPath: keyPath] }, set: { value[keyPath: keyPath] = $0 })
        }
    }
}
#endif


#if os(iOS)
public enum ToolbarPlacementCompat { case navigationBar, tabBar, bottomBar, windowToolbar }
public enum ScrollIndicatorVisibilityCompat { case automatic, visible, hidden, never }
public enum ScrollBounceBehaviorCompat { case automatic, always, basedOnSize }
public enum ContentTransitionCompat {
    case identity, opacity, interpolate, numericText(countsDown: Bool = false)
    public static var numericText: ContentTransitionCompat { .numericText(countsDown: false) }
}
public enum SymbolEffectCompat { case bounce, pulse, variableColor, scale, appear, disappear }
public enum ButtonRepeatBehaviorCompat { case automatic, enabled, disabled }
public struct RectangleCornerRadiiCompat: Equatable {
    public var topLeading: CGFloat, bottomLeading: CGFloat, bottomTrailing: CGFloat, topTrailing: CGFloat
    public init(topLeading: CGFloat = 0, bottomLeading: CGFloat = 0, bottomTrailing: CGFloat = 0, topTrailing: CGFloat = 0) {
        self.topLeading = topLeading; self.bottomLeading = bottomLeading
        self.bottomTrailing = bottomTrailing; self.topTrailing = topTrailing
    }
}
public final class OSAllocatedUnfairLockCompat<State> {
    private var state: State; private let lock = NSLock()
    public init(initialState: State) { self.state = initialState }
    public func withLock<R>(_ body: (inout State) throws -> R) rethrows -> R {
        lock.lock(); defer { lock.unlock() }; return try body(&state)
    }
}
public struct GlassEffectContainer<Content: View>: View {
    let content: Content
    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View { content }
}
public struct AnyLayoutCompat {
    public init<L>(_ layout: L) {}
    public func callAsFunction<Content: View>(@ViewBuilder _ content: () -> Content) -> some View { content() }
}
public struct NavigationLinkCompat<Label: View>: View {
    let label: Label
    public init<P: Hashable>(value: P?, @ViewBuilder label: () -> Label) { self.label = label() }
    public var body: some View { label }
}
@available(iOS 15.0, *)
public extension URL {
    static var applicationSupportDirectoryCompat: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }
    static var documentsDirectoryCompat: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }
    static var cachesDirectoryCompat: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }
    static var temporaryDirectoryCompat: URL { URL(fileURLWithPath: NSTemporaryDirectory()) }
}
@available(iOS 15.0, *)
public extension Shape {
    func fillCompat<S: ShapeStyle>(_ content: S, style: FillStyle = FillStyle()) -> some View { self.fill(content, style: style) }
    func strokeCompat<S: ShapeStyle>(_ content: S, lineWidth: CGFloat = 1) -> some View { self.stroke(content, lineWidth: lineWidth) }
    func strokeCompat<S: ShapeStyle>(_ content: S, style: StrokeStyle) -> some View { self.stroke(content, style: style) }
}
@available(iOS 15.0, *)
public extension View {
    @ViewBuilder func toolbarBackgroundCompat(_ visibility: Visibility, for bars: ToolbarPlacementCompat...) -> some View { self }
    @ViewBuilder func presentationBackgroundCompat<S: ShapeStyle>(_ style: S) -> some View {
        if #available(iOS 16.4, *) { self.presentationBackground(style) } else { self }
    }
    @ViewBuilder func onChangeCompat<V: Equatable>(of value: V, initial: Bool, perform action: @escaping (_ oldValue: V, _ newValue: V) -> Void) -> some View {
        self.modifier(OnChangeTwoArgModifier(value: value, initial: initial, action: action))
    }
    @ViewBuilder func onChangeCompat<V: Equatable>(of value: V, initial: Bool, perform action: @escaping (_ newValue: V) -> Void) -> some View {
        self.onChange(of: value, perform: action)
    }
    @ViewBuilder func scrollIndicatorsCompat(_ visibility: ScrollIndicatorVisibilityCompat, axes: Axis.Set = [.vertical, .horizontal]) -> some View { self }
    @ViewBuilder func contentTransitionCompat(_ transition: ContentTransitionCompat) -> some View { self }
    @ViewBuilder func scrollDisabledCompat(_ disabled: Bool) -> some View { self }
    @ViewBuilder func scrollBounceBehaviorCompat(_ behavior: ScrollBounceBehaviorCompat, axes: Axis.Set = [.vertical]) -> some View { self }
    @ViewBuilder func persistentSystemOverlaysCompat(_ visibility: Visibility) -> some View { self }
    @ViewBuilder func contentMarginsCompat(_ edges: Edge.Set = .all, _ length: CGFloat?, for placement: Any? = nil) -> some View { self }
    @ViewBuilder func focusableCompat(_ isFocusable: Bool = true) -> some View { self }
    @ViewBuilder func scrollTargetLayoutCompat(isEnabled: Bool = true) -> some View { self }
    @ViewBuilder func symbolEffectCompat(_ effect: SymbolEffectCompat, options: Any? = nil, value: Any? = nil) -> some View { self }
    @ViewBuilder func scrollEdgeEffectHiddenCompat(_ hidden: Bool = true, for edges: Edge.Set = .all) -> some View { self }
    @ViewBuilder func buttonRepeatBehaviorCompat(_ behavior: ButtonRepeatBehaviorCompat) -> some View { self }
    @ViewBuilder func glassEffectCompat(_ style: Any? = nil, in shape: Any? = nil) -> some View { self }
    @ViewBuilder func navigationDestinationCompat<D: Hashable, C: View>(for data: D.Type, @ViewBuilder destination: @escaping (D) -> C) -> some View { self }
    @ViewBuilder func navigationDestinationCompat<C: View>(isPresented: Binding<Bool>, @ViewBuilder destination: () -> C) -> some View { self }
    @ViewBuilder func navigationDestinationCompat<V: Hashable, C: View>(item: Binding<V?>, @ViewBuilder destination: @escaping (V) -> C) -> some View { self }
}
#endif
