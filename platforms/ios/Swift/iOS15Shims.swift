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


public extension Shape {
    @inlinable
    func fill<S: ShapeStyle>(_ content: S) -> some View {
        ZStack { self }.foregroundStyle(content)
    }

    @inlinable
    func stroke<S: ShapeStyle>(_ content: S, lineWidth: CGFloat = 1) -> some View {
        self.stroke(lineWidth: lineWidth).foregroundStyle(content)
    }
}


public extension URL {
    static var applicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
    }
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents", isDirectory: true)
    }
    static var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Caches", isDirectory: true)
    }
    static var temporaryDirectory: URL {
        FileManager.default.temporaryDirectory
    }

}
public extension View {
    func onChangeCompat<V: Equatable>(of value: V, initial: Bool = false, perform action: @escaping () -> Void) -> some View {
        self.onChange(of: value) { _ in action() }
            .onAppear { if initial { action() } }
    }

    func onChangeCompat<V: Equatable>(of value: V, initial: Bool = false, perform action: @escaping (V, V) -> Void) -> some View {
        self.modifier(OnChangeTwoArgModifier(value: value, initial: initial, action: action))
    }
}


@available(iOS, deprecated: 16.0)
public final class OSAllocatedUnfairLock<State>: @unchecked Sendable {
    private let lockPtr: os_unfair_lock_t
    private var state: State

    public init(initialState: State) {
        self.lockPtr = .allocate(capacity: 1)
        self.lockPtr.initialize(to: os_unfair_lock())
        self.state = initialState
    }

    deinit {
        lockPtr.deinitialize(count: 1)
        lockPtr.deallocate()
    }

    @discardableResult
    public func withLock<R>(_ body: (inout State) throws -> R) rethrows -> R {
        os_unfair_lock_lock(lockPtr)
        defer { os_unfair_lock_unlock(lockPtr) }
        return try body(&state)
    }

    public func withLockIfAvailable<R>(_ body: (inout State) throws -> R) rethrows -> R? {
        guard os_unfair_lock_trylock(lockPtr) else { return nil }
        defer { os_unfair_lock_unlock(lockPtr) }
        return try body(&state)
    }
}

public extension OSAllocatedUnfairLock where State == Void {
    convenience init() {
        self.init(initialState: ())
    }

    @discardableResult
    func withLock<R>(_ body: () throws -> R) rethrows -> R {
        os_unfair_lock_lock(lockPtr)
        defer { os_unfair_lock_unlock(lockPtr) }
        return try body()
    }
}




// MARK: - Complete iOS 16/17 UI & Layout Backports for iOS 15

public extension LabeledContent where Label == Text, Content == Text {
    init<S1: StringProtocol, S2: StringProtocol>(_ title: S1, value: S2) {
        self.label = Text(title)
        self.content = Text(value)
    }
}


@available(iOS, deprecated: 16.0)
public protocol LayoutCompat {
    associatedtype Body: View = AnyView
    func makeBody<Content: View>(@ViewBuilder content: () -> Content) -> Body
}

@available(iOS, deprecated: 16.0)
public struct HStackLayout: LayoutCompat {
    public var alignment: VerticalAlignment
    public var spacing: CGFloat?
    public init(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }
    public func makeBody<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: alignment, spacing: spacing, content: content)
    }
}

@available(iOS, deprecated: 16.0)
public struct VStackLayout: LayoutCompat {
    public var alignment: HorizontalAlignment
    public var spacing: CGFloat?
    public init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }
    public func makeBody<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: alignment, spacing: spacing, content: content)
    }
}

@available(iOS, deprecated: 16.0)
public struct ZStackLayout: LayoutCompat {
    public var alignment: Alignment
    public init(alignment: Alignment = .center) {
        self.alignment = alignment
    }
    public func makeBody<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: alignment, content: content)
    }
}

@available(iOS, deprecated: 16.0)
public struct AnyLayout {
    private let builder: (AnyView) -> AnyView
    public init<L: LayoutCompat>(_ layout: L) {
        self.builder = { content in
            AnyView(layout.makeBody { content })
        }
    }
    public func callAsFunction<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        builder(AnyView(content()))
    }
}

@available(iOS, deprecated: 16.0)
public enum ToolbarPlacementCompat {
    case automatic, bottomBar, navigationBar, tabBar
}

@available(iOS, deprecated: 17.0)
public enum ContentMarginsPlacementCompat {
    case automatic, scrollContent, scrollIndicators
}

@available(iOS, deprecated: 16.0)
public enum ContentTransitionCompat {
    case identity, opacity, interpolate, numericText(countsDown: Bool = false)
    public static var numericText: ContentTransitionCompat { .numericText() }
}

public extension View {
    func contentMargins(_ edges: Edge.Set = .all, _ length: CGFloat?, for placement: ContentMarginsPlacementCompat = .automatic) -> some View { self }
    func contentMargins(_ length: CGFloat, for placement: ContentMarginsPlacementCompat = .automatic) -> some View { self }
    func toolbarBackground(_ visibility: Visibility, for bars: ToolbarPlacementCompat...) -> some View { self }
    func toolbarBackground<S: ShapeStyle>(_ style: S, for bars: ToolbarPlacementCompat...) -> some View { self }
    func presentationBackground<S: ShapeStyle>(_ style: S) -> some View { self }
    func presentationBackground<V: View>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View { self }
    func fontWeight(_ weight: Font.Weight?) -> some View { self }
    func contentTransition(_ transition: ContentTransitionCompat) -> some View { self }
    func scrollPosition<ID: Hashable>(id: Binding<ID?>, anchor: UnitPoint? = nil) -> some View { self }
    func foregroundStyle<S1: ShapeStyle, S2: ShapeStyle>(_ primary: S1, _ secondary: S2) -> some View {
        self.foregroundStyle(primary)
    }
    func navigationDestination<V: View>(isPresented: Binding<Bool>, destination: () -> V) -> some View {
        self.background(
            NavigationLink(destination: destination(), isActive: isPresented) { EmptyView() }.hidden()
        )
    }
    func navigationDestination<D: Hashable, C: View>(for data: D.Type, destination: @escaping (D) -> C) -> some View { self }
    func navigationDestination<D: Identifiable, C: View>(item: Binding<D?>, destination: @escaping (D) -> C) -> some View {
        self.background(
            NavigationLink(
                destination: Group { if let val = item.wrappedValue { destination(val) } },
                isActive: Binding(
                    get: { item.wrappedValue != nil },
                    set: { if !$0 { item.wrappedValue = nil } }
                )
            ) { EmptyView() }.hidden()
        )
    }
}


// MARK: - UnevenRoundedRectangle & Scroll Shims for iOS 15

@available(iOS, deprecated: 16.0)
public struct RectangleCornerRadii: Equatable, Sendable {
    public var topLeading: CGFloat
    public var bottomLeading: CGFloat
    public var bottomTrailing: CGFloat
    public var topTrailing: CGFloat

    public init(topLeading: CGFloat = 0, bottomLeading: CGFloat = 0, bottomTrailing: CGFloat = 0, topTrailing: CGFloat = 0) {
        self.topLeading = topLeading
        self.bottomLeading = bottomLeading
        self.bottomTrailing = bottomTrailing
        self.topTrailing = topTrailing
    }
}

@available(iOS, deprecated: 16.0)
public struct UnevenRoundedRectangle: Shape, Sendable {
    public var cornerRadii: RectangleCornerRadii
    public var style: RoundedCornerStyle

    public init(cornerRadii: RectangleCornerRadii, style: RoundedCornerStyle = .continuous) {
        self.cornerRadii = cornerRadii
        self.style = style
    }

    public init(topLeadingRadius: CGFloat = 0, bottomLeadingRadius: CGFloat = 0, bottomTrailingRadius: CGFloat = 0, topTrailingRadius: CGFloat = 0, style: RoundedCornerStyle = .continuous) {
        self.cornerRadii = RectangleCornerRadii(
            topLeading: topLeadingRadius,
            bottomLeading: bottomLeadingRadius,
            bottomTrailing: bottomTrailingRadius,
            topTrailing: topTrailingRadius
        )
        self.style = style
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl = min(min(cornerRadii.topLeading, rect.width / 2), rect.height / 2)
        let tr = min(min(cornerRadii.topTrailing, rect.width / 2), rect.height / 2)
        let bl = min(min(cornerRadii.bottomLeading, rect.width / 2), rect.height / 2)
        let br = min(min(cornerRadii.bottomTrailing, rect.width / 2), rect.height / 2)

        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        if tr > 0 {
            path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        if br > 0 {
            path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        }
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        if bl > 0 {
            path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        if tl > 0 {
            path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }
        path.closeSubpath()
        return path
    }
}

@available(iOS, deprecated: 16.0)
public enum ScrollIndicatorVisibilityCompat: Sendable {
    case automatic, visible, hidden, never
}

@available(iOS, deprecated: 16.4)
public enum ScrollBounceBehaviorCompat: Sendable {
    case automatic, always, basedOnSize
}

public extension View {
    func scrollIndicators(_ visibility: ScrollIndicatorVisibilityCompat, axes: Axis.Set = [.vertical, .horizontal]) -> some View { self }
    func scrollBounceBehavior(_ behavior: ScrollBounceBehaviorCompat, axes: Axis.Set = [.vertical]) -> some View { self }
}


// MARK: - Bindable & Focus/Scroll Modifiers for iOS 15

@available(iOS, deprecated: 17.0)
@dynamicMemberLookup
public struct Bindable<Value: AnyObject> {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public init(_ wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<Value, Subject>) -> Binding<Subject> {
        Binding(
            get: { self.wrappedValue[keyPath: keyPath] },
            set: { self.wrappedValue[keyPath: keyPath] = $0 }
        )
    }
}

public extension View {
    func focusEffectDisabled(_ disabled: Bool = true) -> some View { self }
    func persistentSystemOverlays(_ visibility: Visibility) -> some View { self }
    func scrollDisabled(_ disabled: Bool) -> some View { self }
    func defersSystemGestures(on edges: Edge.Set) -> some View { self }
}


// MARK: - ProposedViewSize & Liquid Glass / ButtonRepeat Shims for iOS 15

@available(iOS, deprecated: 16.0)
public struct ProposedViewSize: Equatable, Sendable {
    public var width: CGFloat?
    public var height: CGFloat?

    public static let zero = ProposedViewSize(width: 0, height: 0)
    public static let unspecified = ProposedViewSize(width: nil, height: nil)
    public static let infinity = ProposedViewSize(width: .infinity, height: .infinity)

    public init(width: CGFloat?, height: CGFloat?) {
        self.width = width
        self.height = height
    }

    public init(_ size: CGSize) {
        self.width = size.width
        self.height = size.height
    }

    public func replacingUnspecifiedDimensions(by size: CGSize = CGSize(width: 10, height: 10)) -> CGSize {
        CGSize(width: width ?? size.width, height: height ?? size.height)
    }
}

@available(iOS, deprecated: 26.0)
public struct GlassEffectContainer<Content: View>: View {
    public var spacing: CGFloat?
    public let content: Content

    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        content
    }
}

@available(iOS, deprecated: 26.0)
public struct GlassCompat: Sendable {
    public static let regular = GlassCompat()
    public static let clear = GlassCompat()
    public static let identity = GlassCompat()

    public init() {}

    public func tint(_ color: Color?) -> GlassCompat { self }
    public func interactive(_ isEnabled: Bool = true) -> GlassCompat { self }
}

@available(iOS, deprecated: 26.0)
public struct GlassEffectShapeCompat: Sendable {
    public static let circle = GlassEffectShapeCompat()
    public static let capsule = GlassEffectShapeCompat()
    public static let rect = GlassEffectShapeCompat()

    public init() {}

    public static func rect(cornerRadius: CGFloat, style: RoundedCornerStyle = .continuous) -> GlassEffectShapeCompat {
        GlassEffectShapeCompat()
    }
    public static func rect(cornerRadii: RectangleCornerRadii, style: RoundedCornerStyle = .continuous) -> GlassEffectShapeCompat {
        GlassEffectShapeCompat()
    }
}

@available(iOS, deprecated: 26.0)
public enum GlassEffectTransitionCompat: Sendable {
    case identity
    case matchedGeometry
    case materialize
}

@available(iOS, deprecated: 17.0)
public enum ButtonRepeatBehaviorCompat: Sendable {
    case automatic
    case enabled
    case disabled
}

public extension View {
    func glassEffect(_ glass: GlassCompat = .regular, in shape: GlassEffectShapeCompat = .capsule) -> some View { self }
    func glassEffectID<ID: Hashable>(_ id: ID, in namespace: Namespace.ID) -> some View { self }
    func glassEffectTransition(_ transition: GlassEffectTransitionCompat) -> some View { self }
    func buttonRepeatBehavior(_ behavior: ButtonRepeatBehaviorCompat) -> some View { self }
}

#endif

public extension View {
    @ViewBuilder
    func fontWeightCompat(_ weight: Font.Weight) -> some View {
        if #available(iOS 16.0, *) {
            fontWeight(weight)
        } else {
            self
        }
    }
}
