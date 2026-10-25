import SwiftUI

/// Plus: the Service planner. Plan a Sabbath (or any) service: the hymns in order, with the parts of
/// worship around them, then share it as a printed style programme.
struct WorshipService: Codable, Identifiable, Hashable {
    var id = UUID().uuidString
    var title: String
    var date: Date
    var church: String = ""
    var slots: [Slot]

    struct Slot: Codable, Identifiable, Hashable {
        var id = UUID().uuidString
        var part: String
        var hymn: Int?
        var note: String = ""
    }

    static func sabbath(on date: Date) -> WorshipService {
        WorshipService(title: t("planner.defaultTitle"), date: date, slots: [
            Slot(part: t("planner.part.opening")),
            Slot(part: t("planner.part.praise")),
            Slot(part: t("planner.part.scripture")),
            Slot(part: t("planner.part.sermon")),
            Slot(part: t("planner.part.closing")),
            Slot(part: t("planner.part.benediction")),
        ])
    }
}

@MainActor
final class ServiceStore: ObservableObject {
    static let shared = ServiceStore()
    @Published private(set) var services: [WorshipService] = []
    private let key = "hymnal.services"

    init() {
        if let d = UserDefaults.standard.data(forKey: key), let s = try? JSONDecoder().decode([WorshipService].self, from: d) { services = s }
    }

    func save(_ s: WorshipService) {
        if let i = services.firstIndex(where: { $0.id == s.id }) { services[i] = s } else { services.insert(s, at: 0) }
        services.sort { $0.date > $1.date }
        persist()
    }

    func delete(_ id: String) { services.removeAll { $0.id == id }; persist() }

    private func persist() {
        if let d = try? JSONEncoder().encode(services) { UserDefaults.standard.set(d, forKey: key) }
    }

    /// The coming Saturday (or today when it's the Sabbath).
    static var nextSabbath: Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let wd = cal.component(.weekday, from: today)
        return cal.date(byAdding: .day, value: (7 - wd + 7) % 7, to: today) ?? today
    }
}

struct ServiceListView: View {
    @ObservedObject private var store = ServiceStore.shared
    @State private var editing: WorshipService?

    var body: some View {
        List {
            Section {
                Button {
                    editing = WorshipService.sabbath(on: ServiceStore.nextSabbath)
                } label: {
                    Label(t("planner.new"), systemImage: "plus.circle.fill").font(.body.weight(.semibold))
                }
            } footer: { Text(t("planner.footer")) }
            if !store.services.isEmpty {
                Section {
                    ForEach(store.services) { s in
                        Button { editing = s } label: {
                            HStack(spacing: 14) {
                                VStack(spacing: 0) {
                                    Text(s.date.formatted(.dateTime.month(.abbreviated))).font(.caption2.weight(.bold)).textCase(.uppercase).foregroundStyle(Color.brand)
                                    Text(s.date.formatted(.dateTime.day())).font(.serif(22, .bold)).foregroundStyle(Color.ink)
                                }
                                .frame(width: 48, height: 52)
                                .background(Color.brand.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.title).font(.body.weight(.medium)).foregroundStyle(Color.ink).lineLimit(1)
                                    Text(t("lists.hymnsCount", ["n": s.slots.compactMap(\.hymn).count])).font(.footnote).foregroundStyle(Color.inkSoft).lineLimit(1)
                                }
                            }
                        }
                    }
                    .onDelete { idx in for i in idx { store.delete(store.services[i].id) } }
                }
            }
        }
        .listStyle(.insetGrouped)
        .tracksScroll()
        .navigationTitle(t("plus.planner.title"))
        .toolbar(.visible, for: .navigationBar)
        .fullScreenCover(item: $editing) { ServiceEditor(service: $0) }
    }
}

struct ServiceEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var service: WorshipService
    @State private var picking: String?
    @State private var showProgramme = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(t("planner.titleField"), text: $service.title)
                    TextField(t("planner.church"), text: $service.church)
                    DatePicker(t("planner.date"), selection: $service.date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                Section(t("planner.order")) {
                    ForEach($service.slots) { $slot in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField(t("planner.part"), text: $slot.part).font(.subheadline.weight(.semibold))
                            Button { picking = slot.id } label: {
                                HStack {
                                    if let n = slot.hymn, let h = HymnBook.shared.hymn(n) {
                                        Text("\(n)").font(.serif(17, .semibold)).foregroundStyle(Color.brand)
                                        Text(h.title).foregroundStyle(Color.ink).lineLimit(1)
                                    } else {
                                        Image(systemName: "music.note").foregroundStyle(Color.inkFaint)
                                        Text(t("planner.addHymn")).foregroundStyle(Color.inkSoft)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.inkFaint)
                                }
                            }
                            .buttonStyle(.plain)
                            TextField(t("planner.note"), text: $slot.note).font(.footnote).foregroundStyle(Color.inkSoft)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { service.slots.remove(atOffsets: $0) }
                    .onMove { service.slots.move(fromOffsets: $0, toOffset: $1) }
                    Button { service.slots.append(.init(part: t("planner.part.hymn"))) } label: {
                        Label(t("planner.addPart"), systemImage: "plus")
                    }
                }
                Section {
                    Button { showProgramme = true } label: {
                        Label(t("planner.share"), systemImage: "square.and.arrow.up").font(.body.weight(.semibold))
                    }
                }
            }
            .navigationTitle(service.title.isEmpty ? t("planner.defaultTitle") : service.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(t("common.cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("common.save")) { ServiceStore.shared.save(service); dismiss() }.fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
            .fullScreenCover(item: Binding(get: { picking.map { PickID(id: $0) } }, set: { picking = $0?.id })) { p in
                SingleHymnPicker { n in
                    if let i = service.slots.firstIndex(where: { $0.id == p.id }) { service.slots[i].hymn = n }
                }
            }
            .fullScreenCover(isPresented: $showProgramme) { ProgrammeView(service: service) }
        }
    }

    private struct PickID: Identifiable { let id: String }
}

/// Choose one hymn.
struct SingleHymnPicker: View {
    let pick: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var hymns: [Hymn] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return HymnBook.shared.hymns }
        if let n = Int(q), let h = HymnBook.shared.hymn(n) { return [h] }
        let r = HymnBook.shared.search(q)
        return r.titles + r.elsewhere
    }

    var body: some View {
        NavigationStack {
            List(hymns) { h in
                Button { pick(h.number); dismiss() } label: { HymnRow(hymn: h, subtitle: h.section) }
                    .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: t("home.search"))
            .navigationTitle(t("planner.addHymn"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(t("common.cancel")) { dismiss() } } }
        }
    }
}

/// The service as a printed style programme to share.
struct ProgrammeView: View {
    let service: WorshipService
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                ProgrammeCard(service: service)
                    .frame(width: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
                    .padding(24)
            }
            .background(Color.card)
            .navigationTitle(t("planner.programme"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(t("common.close")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if let image {
                        ShareLink(item: Image(uiImage: image), preview: SharePreview(service.title, image: Image(uiImage: image))) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .onAppear {
                let r = ImageRenderer(content: ProgrammeCard(service: service).frame(width: 360))
                r.scale = 3
                image = r.uiImage
            }
        }
    }
}

struct ProgrammeCard: View {
    let service: WorshipService

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                SDALogo(size: 34, color: Color(hex: "B8862F"))
                Text(t("planner.orderOfWorship")).font(.system(size: 11, weight: .semibold)).tracking(2.4).textCase(.uppercase)
                    .foregroundStyle(Color(hex: "8A6A3A"))
                Text(service.title).font(.serif(26, .semibold)).foregroundStyle(Color(hex: "2A2118")).multilineTextAlignment(.center)
                Text(service.date.formatted(date: .complete, time: .omitted)).font(.serif(13).italic()).foregroundStyle(Color(hex: "6B5B45"))
                if !service.church.isEmpty {
                    Text(service.church).font(.system(size: 12, weight: .medium)).foregroundStyle(Color(hex: "6B5B45"))
                }
            }
            .padding(.top, 30).padding(.bottom, 20)
            Rectangle().fill(Color(hex: "D9C7A3")).frame(width: 60, height: 1).padding(.bottom, 18)
            VStack(spacing: 14) {
                ForEach(service.slots) { s in
                    VStack(spacing: 3) {
                        Text(s.part).font(.system(size: 10, weight: .bold)).tracking(1.6).textCase(.uppercase).foregroundStyle(Color(hex: "8A6A3A"))
                        if let n = s.hymn, let h = HymnBook.shared.hymn(n) {
                            Text("\(n) · \(h.title)").font(.serif(16, .semibold)).foregroundStyle(Color(hex: "2A2118")).multilineTextAlignment(.center)
                        }
                        if !s.note.isEmpty {
                            Text(s.note).font(.serif(13).italic()).foregroundStyle(Color(hex: "6B5B45")).multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .padding(.horizontal, 28)
            Text("SDA Hymnal").font(.system(size: 10, weight: .semibold)).tracking(1.2).foregroundStyle(Color(hex: "B8A27A"))
                .padding(.top, 26).padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [Color(hex: "FBF6EC"), Color(hex: "F3E9D6")], startPoint: .top, endPoint: .bottom))
        .environment(\.colorScheme, .light)
    }
}
