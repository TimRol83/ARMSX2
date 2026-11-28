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

}

public struct PhotosPickerItemCompat: Hashable {
    public var supportedContentTypes: [Any] { [] }
    public init() {}
    public func loadTransferable<T>(type: T.Type) async throws -> T? { return nil }
}

public struct MagnifyGesture: Gesture {
    public struct Value: Equatable {
        public var magnification: CGFloat = 1.0
        public var velocity: CGFloat = 0.0
        public var startAnchor: UnitPoint = .center
        public var startLocation: CGPoint = .zero
    }
    public init(minimumScaleDelta: CGFloat = 0.01) {}
    public var body: some Gesture {
        MagnificationGesture().map { scale in
            var v = Value()
            v.magnification = scale
            return v
        }
    }
}

public struct AnimationContext<Value> {
    public var value: Value
    public init(value: Value) { self.value = value }
}

public enum AccessibilityNotification {
    public struct Announcement {
        public init(_ text: String) {}
        public func post() {}
    }
}

public enum DurationUnitsStyleCompat { case abbreviated, narrow, wide }
public struct DurationFormatStyleCompat {
    public init(allowedUnits: Set<Calendar.Component> = [.minute, .second], unitsStyle: DurationUnitsStyleCompat = .abbreviated) {}
    public static func units(allowed: Set<Calendar.Component>, width: DurationUnitsStyleCompat = .abbreviated) -> DurationFormatStyleCompat {
        DurationFormatStyleCompat(allowedUnits: allowed, unitsStyle: width)
    }
}

public extension GlassStyleCompat {
    func tint(_ color: Color?) -> GlassStyleCompat { self }
    static func rect(cornerRadius: CGFloat) -> GlassStyleCompat { .rect }
}

public extension ContentTransitionCompat {
    static func symbolEffect(_ effect: SymbolEffectCompat = .automatic) -> ContentTransitionCompat { .identity }
}

public extension SymbolEffectCompat {
    static var automatic: SymbolEffectCompat { .bounce }
}

@available(iOS 15.0, *)
public extension View {
    @ViewBuilder func onChangeCompat<V: Equatable>(of value: V, perform action: @escaping () -> Void) -> some View {
        self.onChange(of: value) { _ in action() }
    }
    @ViewBuilder func onChangeCompat<V: Equatable>(of value: V, initial: Bool, perform action: @escaping () -> Void) -> some View {
        self.onChange(of: value) { _ in action() }
    }
    @ViewBuilder func lineLimitCompat(_ limit: ClosedRange<Int>) -> some View {
        self.lineLimit(limit.upperBound)
    }
    @ViewBuilder func lineLimitCompat(_ limit: PartialRangeThrough<Int>) -> some View {
        self.lineLimit(limit.upperBound)
    }
    @ViewBuilder func lineLimitCompat(_ limit: PartialRangeFrom<Int>) -> some View {
        self.lineLimit(nil)
    }
    @ViewBuilder func photosPickerCompat(isPresented: Binding<Bool>, selection: Any?, matching: PHPickerFilterCompat? = nil, preferredItemEncoding: Any? = nil) -> some View {
        self
    }
    
    @ViewBuilder func toolbarCompat<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        self.toolbar { content() }
    }
}

@available(iOS 15.0, *)
public extension Image {
    init(at url: URL) {
        if let ui = UIImage(contentsOfFile: url.path) {
            self.init(uiImage: ui)
        } else {
            self.init(systemName: "photo")
        }
    }
}

@available(iOS 15.0, *)
public extension TextField where Label == Text {
    init<S: StringProtocol>(_ title: S, text: Binding<String>, axis: Axis) {
        self.init(title, text: text)
    }
}

@available(iOS 15.0, *)
public extension RectangleCornerRadiiCompat {
    init(_ radii: RectangleCornerRadiiCompat) {
        self = radii
    }
}
#endif
