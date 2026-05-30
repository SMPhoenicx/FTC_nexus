import SwiftUI

// MARK: - Events View

struct EventsView: View {
    @Environment(\.nexusTheme) var t
    @StateObject private var vm = EventsViewModel()
    @State private var showFilterSheet = false

    private let seasons: [Int] = {
        let cal = Calendar.current
        let y   = cal.component(.year, from: Date())
        let m   = cal.component(.month, from: Date())
        let cur = m >= 9 ? y : y - 1
        return Array((2019 ... cur).reversed())
    }()

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                headerSection
                searchAndFilterBar
                Divider().background(t.divider)
                contentArea
            }
        }
        .onAppear { Task { await vm.load() } }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(vm: vm)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Events")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(t.textPrimary)
                    .tracking(-0.6)
                Text(verbatim: "\(seasonName(vm.season).uppercased()) · \(vm.season)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(t.accent)
                    .tracking(0.4)
            }
            Spacer()
            Menu {
                ForEach(seasons, id: \.self) { s in
                    Button("\(s)") { vm.changeSeason(to: s) }
                }
            } label: {
                NeumorphicCard(radius: 12, padding: .init(top: 8, leading: 12, bottom: 8, trailing: 12)) {
                    HStack(spacing: 5) {
                        Text(verbatim: "\(vm.season)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(t.textSecondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(t.textSubtle)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    // MARK: - Search + Filter bar

    private var searchAndFilterBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                NeumorphicInset {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundColor(t.textSubtle)
                        TextField("Search events, cities…", text: $vm.searchQuery)
                            .font(.system(size: 14))
                            .foregroundColor(t.textPrimary)
                            .tint(t.accent)
                            .autocorrectionDisabled()
                        if !vm.searchQuery.isEmpty {
                            Button { vm.searchQuery = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(t.textSubtle)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                }

                Button { showFilterSheet = true } label: {
                    NeumorphicCard(radius: 12, padding: .init(top: 9, leading: 11, bottom: 9, trailing: 11)) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(vm.hasActiveFilters ? t.accent : t.textSubtle)
                            if vm.hasActiveFilters {
                                Circle()
                                    .fill(t.accent)
                                    .frame(width: 7, height: 7)
                                    .offset(x: 3, y: -3)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            if vm.hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        if let team = vm.filterTeamNumber {
                            ActiveFilterPill(label: "Team \(team)") { vm.filterTeamNumber = nil }
                        }
                        if let region = vm.filterRegion {
                            ActiveFilterPill(label: region) { vm.filterRegion = nil }
                        }
                        if let type = vm.filterEventType {
                            ActiveFilterPill(label: type) { vm.filterEventType = nil }
                        }
                        Button { vm.clearAllFilters() } label: {
                            Text("Clear all")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(t.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if vm.isLoading {
            Spacer()
            ProgressView().tint(t.accent).scaleEffect(1.2)
            Text("Loading events…")
                .font(.system(size: 13))
                .foregroundColor(t.textSubtle)
                .padding(.top, 10)
            Spacer()
        } else if let error = vm.errorMessage {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36))
                    .foregroundColor(t.loss)
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(t.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Retry") { Task { await vm.load() } }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(t.accent)
                    .padding(.horizontal, 24).padding(.vertical, 10)
                    .background(Capsule().fill(t.accentMuted))
            }
            Spacer()
        } else if vm.isCurrentSeason {
            currentSeasonContent
        } else {
            pastSeasonContent
        }
    }

    // MARK: - Current season layout

    private var currentSeasonContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !$vm.todayEvents.isEmpty {
                    todayStrip
                }
                if !vm.upcomingGroups.isEmpty {
                    SectionHeader(label: "UPCOMING")
                    ForEach(vm.upcomingGroups, id: \.dateLabel) { group in
                        DateGroupHeader(label: group.dateLabel)
                        ForEach(group.events) { ev in
                            EventRow(event: ev)
                            Divider().background(t.divider).padding(.leading, 16)
                        }
                    }
                }
                if !vm.pastEvents.isEmpty {
                    PastSection(events: vm.pastEvents)
                }
                if vm.filteredEvents.isEmpty {
                    emptyState
                }
            }
        }
    }

    // MARK: - Past season layout

    private var pastSeasonContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(t.blue)
                        .font(.system(size: 13))
                    Text("\(seasonName(vm.season)) season complete")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(t.textSecondary)
                    Spacer()
                    Text(verbatim: "\($vm.allFilteredEvents.count) events")
                        .font(.system(size: 11))
                        .foregroundColor(t.textSubtle)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(t.blueMuted)

                Divider().background(t.divider)

                if vm.allFilteredEvents.isEmpty {
                    emptyState
                } else {
                    ForEach(vm.allFilteredEvents) { ev in
                        EventRow(event: ev)
                        Divider().background(t.divider).padding(.leading, 16)
                    }
                }
            }
        }
    }

    // MARK: - Today strip

    private var todayStrip: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(label: "HAPPENING NOW", accent: true)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.todayEvents) { ev in
                        TodayCard(event: ev)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            Divider().background(t.divider)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 36))
                .foregroundColor(t.textSubtle)
            Text(vm.searchQuery.isEmpty && !vm.hasActiveFilters
                 ? "No events found for this season"
                 : "No events match your filters")
                .font(.system(size: 14))
                .foregroundColor(t.textSubtle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 32)
    }

    // MARK: - Helpers

    private func seasonName(_ season: Int) -> String {
        switch season {
        case 2019: return "Skystone"
        case 2020: return "Ultimate Goal"
        case 2021: return "Freight Frenzy"
        case 2022: return "Power Play"
        case 2023: return "Centerstage"
        case 2024: return "Into the Deep"
        case 2025: return "Decode"
        default:   return "Season"
        }
    }
}

// MARK: - Today Card

struct TodayCard: View {
    @Environment(\.nexusTheme) var t
    let event: Event

    var body: some View {
        NeumorphicCard(radius: 16, padding: .init(top: 14, leading: 16, bottom: 14, trailing: 16)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(t.accent)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(t.accent)
                        .tracking(0.6)
                }
                Text(event.name ?? "—")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(t.textPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: 160, alignment: .leading)
                if let type = event.typeName ?? event.type {
                    Text(type.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(eventTypeColor(type, t: t))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(eventTypeColor(type, t: t).opacity(0.14)))
                }
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 9))
                        .foregroundColor(t.textSubtle)
                    Text(event.locationString)
                        .font(.system(size: 11))
                        .foregroundColor(t.textSubtle)
                        .lineLimit(1)
                }
            }
        }
        .frame(width: 192)
    }
}

// MARK: - Event Row

struct EventRow: View {
    @Environment(\.nexusTheme) var t
    let event: Event
    @State private var pressed = false

    private var isToday: Bool { event.isToday }

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(event.dayString)
                    .font(.system(size: 20, weight: .black).monospacedDigit())
                    .foregroundColor(isToday ? t.accent : t.textPrimary)
                Text(event.monthString.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.3)
                    .foregroundColor(isToday ? t.accentText : t.textSubtle)
            }
            .frame(width: 38)

            Rectangle()
                .fill(isToday ? t.accent : t.divider)
                .frame(width: 1.5)
                .frame(height: 52)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(event.name ?? "Unknown Event")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(t.textPrimary)
                        .lineLimit(1)
                    if isToday {
                        Text("TODAY")
                            .font(.system(size: 8, weight: .black))
                            .tracking(0.5)
                            .foregroundColor(t.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(t.accentMuted))
                    }
                }
                HStack(spacing: 6) {
                    if let type = event.typeName ?? event.type {
                        Text(type.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.4)
                            .foregroundColor(eventTypeColor(type, t: t))
                    }
                    Text("·")
                        .foregroundColor(t.textSubtle)
                        .font(.system(size: 9))
                    Text(event.locationString)
                        .font(.system(size: 11))
                        .foregroundColor(t.textSubtle)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(t.textSubtle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(pressed ? t.accentMuted : Color.clear)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in pressed = pressing }, perform: {})
    }
}

// MARK: - Past Section (collapsible)

struct PastSection: View {
    @Environment(\.nexusTheme) var t
    let events: [Event]
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { expanded.toggle() }
            } label: {
                HStack {
                    SectionHeader(label: "PAST · \(events.count)")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(t.textSubtle)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.22), value: expanded)
                        .padding(.trailing, 16)
                }
            }
            .buttonStyle(.plain)

            if expanded {
                ForEach(events) { ev in
                    EventRow(event: ev)
                    Divider().background(t.divider).padding(.leading, 16)
                }
            }
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Environment(\.nexusTheme) var t
    @ObservedObject var vm: EventsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var teamInput: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                t.sheetBg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        filterSection(title: "TEAM NUMBER") {
                            NeumorphicInset {
                                HStack {
                                    Image(systemName: "number")
                                        .font(.system(size: 13))
                                        .foregroundColor(t.textSubtle)
                                    TextField("e.g. 16072", text: $teamInput)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 14))
                                        .foregroundColor(t.textPrimary)
                                        .tint(t.accent)
                                        .onChange(of: teamInput) { val in
                                            vm.filterTeamNumber = Int(val)
                                        }
                                }
                            }
                        }

                        filterSection(title: "REGION") {
                            chipGrid(options: EventsViewModel.regions, selected: vm.filterRegion) { r in
                                vm.filterRegion = vm.filterRegion == r ? nil : r
                            }
                        }

                        filterSection(title: "EVENT TYPE") {
                            chipGrid(options: EventsViewModel.eventTypes, selected: vm.filterEventType) { type in
                                vm.filterEventType = vm.filterEventType == type ? nil : type
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") { vm.clearAllFilters(); teamInput = "" }
                        .font(.system(size: 14))
                        .foregroundColor(t.accent)
                        .disabled(!vm.hasActiveFilters)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(t.accent)
                }
            }
        }
    }

    private func filterSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundColor(t.textSubtle)
            content()
        }
    }

    private func chipGrid(
        options: [String],
        selected: String?,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { opt in
                NexusPill(label: opt.uppercased(), isSelected: selected == opt) {
                    onSelect(opt)
                }
            }
        }
    }
}

// MARK: - Shared subviews

struct SectionHeader: View {
    @Environment(\.nexusTheme) var t
    let label: String
    var accent: Bool = false

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .foregroundColor(accent ? t.accent : t.textSubtle)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 6)
    }
}

struct DateGroupHeader: View {
    @Environment(\.nexusTheme) var t
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(t.textSecondary)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }
}

struct ActiveFilterPill: View {
    @Environment(\.nexusTheme) var t
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(t.accentText)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(t.accentText)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(t.accentMuted))
        .overlay(Capsule().strokeBorder(t.accent.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

// MARK: - Helpers

private func eventTypeColor(_ type: String, t: NexusTheme) -> Color {
    switch type.lowercased() {
    case "scrimmage": return Color(hex: "34D399")
    case "league meet": return t.blue
    case "qualifier": return t.accent
    case "championship", "first championship",
         "super qualifier": return Color(hex: "F5C842")
    case "world championship",
         "first world championship": return Color(hex: "F5C842")
    default: return t.textSubtle
    }
}

// MARK: - Event extensions

extension Event {
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
    
    private static var utcCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()
    
    var startDate: Date? {
        guard let s = dateStart else { return nil }
        return Self.isoFormatter.date(from: String(s.prefix(10)))
    }
    
    var endDate: Date? {
        guard let s = dateEnd else { return nil }
        return Self.isoFormatter.date(from: String(s.prefix(10)))
    }
    
    var isToday: Bool {
        guard let start = startDate, let end = endOfEventDay else {
            return false
        }
        let now = Date()
        return start <= now && now <= end
    }
    
    var isPast: Bool {
        guard let end = endOfEventDay else { return false }
        return end < Date()
    }
    
    var endOfEventDay: Date? {
        guard let end = endDate else { return nil }
        return Self.utcCalendar.date(
            bySettingHour: 23, minute: 59, second: 59, of: end
        )
    }
    
    var isUpcoming: Bool {
        guard let start = startDate else { return false }
        return start > Date()
    }
    
    var dayString: String {
        guard let d = startDate else { return "–" }
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: d)
    }
    
    var monthString: String {
        guard let d = startDate else { return "–" }
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: d)
    }
    
    var dateRangeLabel: String {
        guard let start = startDate else { return "–" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        if let end = endDate,
           !Calendar.current.isDate(start, inSameDayAs: end) {
            let endFmt = DateFormatter()
            endFmt.dateFormat = Calendar.current.isDate(
                start, equalTo: end, toGranularity: .month
            ) ? "d" : "MMM d"
            return "\(fmt.string(from: start))–\(endFmt.string(from: end))"
        }
        return fmt.string(from: start)
    }
    
    var weekLabel: String {
        guard let d = startDate else { return "–" }
        let cal = Calendar.current
        let today = Date()
        if cal.isDateInToday(d) { return "Today" }
        if cal.isDateInTomorrow(d) { return "Tomorrow" }
        let comps = cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: today),
            to: cal.startOfDay(for: d)
        )
        let days = comps.day ?? 0
        if days > 0 && days <= 6 {
            let fmt = DateFormatter()
            fmt.dateFormat = "EEEE"
            return fmt.string(from: d)
        }
        if days > 6 && days <= 13 { return "Next Week" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: d)
    }
}

// MARK: - Date Group

struct EventDateGroup {
    let dateLabel: String
    let events: [Event]
}

// MARK: - ViewModel

@MainActor
class EventsViewModel: ObservableObject {

    @Published var allEvents: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var season: Int = currentFTCSeason()

    @Published var searchQuery: String = "" { didSet { applyFilters() } }
    @Published var filterTeamNumber: Int? = nil { didSet { applyFilters() } }
    @Published var filterRegion: String? = nil { didSet { applyFilters() } }
    @Published var filterEventType: String? = nil { didSet { applyFilters() } }

    @Published var todayEvents: [Event] = []
    @Published var upcomingGroups: [EventDateGroup] = []
    @Published var pastEvents: [Event] = []
    @Published var allFilteredEvents: [Event] = []

    static let regions: [String] = [
        "Alabama", "Alaska", "Arizona", "California", "Colorado",
        "Florida", "Georgia", "Illinois", "Michigan", "New York",
        "North Carolina", "Ohio", "Oregon", "Pennsylvania", "Texas",
        "Virginia", "Washington", "International"
    ]

    static let eventTypes: [String] = [
        "Scrimmage", "League Meet", "Qualifier",
        "Super Qualifier", "Championship", "World Championship"
    ]

    private let api = APIReceiver(username: "blitzomen", apiKey: "6C8EC18F-253B-4ED9-91A3-1D5E0A3347CD")

    var isCurrentSeason: Bool { season == currentFTCSeason() }

    var hasActiveFilters: Bool {
        filterTeamNumber != nil || filterRegion != nil || filterEventType != nil
    }

    var filteredEvents: [Event] { allFilteredEvents }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        allEvents = []
        applyFilters()

        do {
            let listings: EventListings = try await api.getEvents(season: season)
            allEvents = (listings.events ?? []).sorted {
                ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast)
            }
            applyFilters()
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func changeSeason(to newSeason: Int) {
        guard newSeason != season else { return }
        season = newSeason
        Task { await load() }
    }

    func clearAllFilters() {
        filterTeamNumber = nil
        filterRegion     = nil
        filterEventType  = nil
        searchQuery      = ""
    }

    private func applyFilters() {
        var events = allEvents

        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            events = events.filter {
                ($0.name?.lowercased().contains(q) ?? false) ||
                ($0.city?.lowercased().contains(q) ?? false) ||
                ($0.stateprov?.lowercased().contains(q) ?? false) ||
                ($0.country?.lowercased().contains(q) ?? false)
            }
        }

        if let region = filterRegion {
            events = events.filter {
                let regionLower = region.lowercased()
                let state = ($0.stateprov ?? "").lowercased()
                let country = ($0.country ?? "").lowercased()
                return state.contains(regionLower)
                    || country.contains(regionLower)
                    || (regionLower == "international" && country != "usa")
            }
        }

        if let type = filterEventType {
            events = events.filter {
                let name = ($0.typeName ?? $0.type ?? "").lowercased()
                return name == type.lowercased()
            }
        }

        allFilteredEvents = events

        // isToday: started on or before now AND ends on or after now
        // isUpcoming: hasn't started yet
        // isPast: end-of-event-day is before today
        // Anything not in those three (shouldn't happen) falls to upcoming
        todayEvents  = events.filter { $0.isToday }
        pastEvents   = events.filter { $0.isPast }.reversed()

        let upcoming = events.filter { $0.isUpcoming }
        var groups: [String: [Event]] = [:]
        var groupOrder: [String] = []
        for ev in upcoming {
            let key = ev.weekLabel
            if groups[key] == nil {
                groupOrder.append(key)
                groups[key] = []
            }
            groups[key]!.append(ev)
        }
        upcomingGroups = groupOrder.map {
            EventDateGroup(dateLabel: $0, events: groups[$0]!)
        }
    }

    func loadForTeam(_ teamNumber: Int) async {
        filterTeamNumber = teamNumber
        isLoading = true
        errorMessage = nil
        do {
            let listings: EventListings = try await api.getEvents(
                season: season, teamNumber: teamNumber
            )
            allEvents = (listings.events ?? []).sorted {
                ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast)
            }
            applyFilters()
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

private func currentFTCSeason() -> Int {
    let cal = Calendar.current
    let now = Date()
    let year  = cal.component(.year, from: now)
    let month = cal.component(.month, from: now)
    return month >= 9 ? year : year - 1
}

// MARK: - Preview

#Preview("Dark · Current Season") {
    EventsView()
        .environment(\.nexusTheme, NexusTheme(isDark: true))
        .preferredColorScheme(.dark)
}

#Preview("Light · Current Season") {
    EventsView()
        .environment(\.nexusTheme, NexusTheme(isDark: false))
        .preferredColorScheme(.light)
}
