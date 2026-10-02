import SwiftUI

struct CycleEducationView: View {
    @Environment(\.locale) private var locale

    var body: some View {
        ScreenContainer(
            title: "cycle.education.title",
            embedsInNavigationStack: false
        ) {
            IOSCard {
                Label("cycle.education.intro.title", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.indigo)

                Text("cycle.education.intro.summary")
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                Text("cycle.education.intro.body")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SectionHeader(title: "cycle.education.section.basics")

            EducationTextCard(
                title: "cycle.education.phases.title",
                summary: "cycle.education.phases.summary",
                bodyText: "cycle.education.phases.body",
                icon: "circle.hexagongrid.fill",
                tint: .blue
            )

            EducationTextCard(
                title: "cycle.education.counting.title",
                summary: "cycle.education.counting.summary",
                bodyText: "cycle.education.counting.body",
                icon: "calendar",
                tint: .green
            )

            SectionHeader(title: "cycle.education.section.estimate")

            EducationTextCard(
                title: "cycle.education.method.title",
                summary: "cycle.education.method.summary",
                bodyText: "cycle.education.method.body",
                icon: "function",
                tint: .indigo
            )

            EducationTextCard(
                title: "cycle.education.variation.title",
                summary: "cycle.education.variation.summary",
                bodyText: "cycle.education.variation.body",
                icon: "waveform.path.ecg",
                tint: .orange
            )

            EducationTextCard(
                title: "cycle.education.contraception.title",
                summary: "cycle.education.contraception.summary",
                bodyText: "cycle.education.contraception.body",
                icon: "pills.fill",
                tint: .purple
            )

            EducationTextCard(
                title: "cycle.education.situations.title",
                summary: "cycle.education.situations.summary",
                bodyText: "cycle.education.situations.body",
                icon: "person.crop.circle.badge.questionmark",
                tint: .pink
            )

            SectionHeader(title: "cycle.education.section.overview")

            ForEach(CycleSection.allCases) { section in
                EducationPhaseCard(
                    section: section,
                    text: overviewText(for: section)
                )
            }

            SectionHeader(title: "cycle.education.section.everyday")

            EducationTextCard(
                title: "cycle.education.experience.title",
                summary: "cycle.education.experience.summary",
                bodyText: "cycle.education.experience.body",
                icon: "brain.head.profile",
                tint: .orange
            )

            EducationTextCard(
                title: "cycle.education.nutrition.title",
                summary: "cycle.education.nutrition.summary",
                bodyText: "cycle.education.nutrition.body",
                icon: "fork.knife",
                tint: .green
            )

            IOSCard {
                Label("cycle.education.safety.title", systemImage: "shield.lefthalf.filled")
                    .font(.headline)
                Text("cycle.education.safety.body")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SectionHeader(title: "cycle.education.section.sources")

            IOSCard {
                Text("cycle.education.sources.intro")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                    if index > 0 {
                        Divider()
                    }

                    Link(destination: source.url) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.topic)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(source.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Text(source.host)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 8)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                Text("cycle.education.sources.reviewed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("cycle.education.sources.externalNote")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func overviewText(for section: CycleSection) -> LocalizedStringResource {
        switch section {
        case .menstruation:
            return "cycle.education.overview.menstruation"
        case .building:
            return "cycle.education.overview.follicular"
        case .ovulationWindow:
            return "cycle.education.overview.ovulation"
        case .luteal:
            return "cycle.education.overview.luteal"
        case .premenstrual:
            return "cycle.education.overview.premenstrual"
        }
    }

    private var sources: [EducationSource] {
        let languageCode = locale.language.languageCode?.identifier ?? "en"

        let usesTraditionalChinese = locale.language.script?.identifier == "Hant"
            || ["TW", "HK", "MO"].contains(locale.region?.identifier ?? "")

        if languageCode == "zh" && usesTraditionalChinese {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.en"),
                    host: "臺大醫院",
                    url: URL(string: "https://epaper.ntuh.gov.tw/health/202505/child_2.html")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.en"),
                    host: "臺北榮民總醫院",
                    url: URL(string: "https://ihealth.vghtpe.gov.tw/media/1189")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.en"),
                    host: "臺北榮民總醫院",
                    url: URL(string: "https://ihealth.vghtpe.gov.tw/media/630")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.ptBR"),
                    host: "衛生福利部",
                    url: URL(string: "https://www.mohw.gov.tw/cp-16-82343-1.html")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.variation.ar"),
                    host: "國民健康署",
                    url: URL(string: "https://www.hpa.gov.tw/Pages/Detail.aspx?nodeid=1149&pid=6613&sid=6618")!
                )
            ]
        }

        if languageCode == "ja" {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.en"),
                    host: "MSDマニュアル家庭版",
                    url: URL(string: "https://www.msdmanuals.com/ja-jp/home/22-%E5%A5%B3%E6%80%A7%E3%81%AE%E5%81%A5%E5%BA%B7%E4%B8%8A%E3%81%AE%E5%95%8F%E9%A1%8C/%E5%A5%B3%E6%80%A7%E3%81%AE%E7%94%9F%E6%AE%96%E5%99%A8%E7%B3%BB%E3%81%AE%E7%94%9F%E7%89%A9%E5%AD%A6/%E6%9C%88%E7%B5%8C%E5%91%A8%E6%9C%9F")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.en"),
                    host: "日本産科婦人科学会",
                    url: URL(string: "https://www.jsog.or.jp/activity/pdf/PMS_PMDDshishin.pdf")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.en"),
                    host: "MSDマニュアル家庭版",
                    url: URL(string: "https://www.msdmanuals.com/ja-jp/home/22-%E5%A5%B3%E6%80%A7%E3%81%AE%E5%81%A5%E5%BA%B7%E4%B8%8A%E3%81%AE%E5%95%8F%E9%A1%8C/%E6%9C%88%E7%B5%8C%E9%9A%9C%E5%AE%B3%E3%81%A8%E7%95%B0%E5%B8%B8%E3%81%AA%E7%95%B0%E5%B8%B8%E5%AD%90%E5%AE%AE%E5%87%BA%E8%A1%80/%E6%9C%88%E7%B5%8C%E7%97%9B")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.ru"),
                    host: "MSDマニュアル家庭版",
                    url: URL(string: "https://www.msdmanuals.com/ja-jp/home/22-%E5%A5%B3%E6%80%A7%E3%81%AE%E5%81%A5%E5%BA%B7%E4%B8%8A%E3%81%AE%E5%95%8F%E9%A1%8C/%E5%AE%B6%E6%97%8F%E8%A8%88%E7%94%BB/%E3%83%9B%E3%83%AB%E3%83%A2%E3%83%B3%E5%89%A4%E3%81%AB%E3%82%88%E3%82%8B%E9%81%BF%E5%A6%8A%E6%B3%95")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.menopause.de"),
                    host: "MSDマニュアル家庭版",
                    url: URL(string: "https://www.msdmanuals.com/ja-jp/home/22-%E5%A5%B3%E6%80%A7%E3%81%AE%E5%81%A5%E5%BA%B7%E4%B8%8A%E3%81%AE%E5%95%8F%E9%A1%8C/%E9%96%89%E7%B5%8C/%E9%96%89%E7%B5%8C")!
                )
            ]
        }

        if languageCode == "vi" {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.en"),
                    host: "Bệnh viện Đa khoa Quốc tế Vinmec",
                    url: URL(string: "https://www.vinmec.com/vie/bai-viet/chu-ky-kinh-nguyet-khi-nao-binh-thuong-khi-nao-bat-thuong-vi")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.en"),
                    host: "Bệnh viện Đa khoa Quốc tế Vinmec",
                    url: URL(string: "https://www.vinmec.com/vie/benh/hoi-chung-tien-kinh-nguyet-4749")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.en"),
                    host: "Bệnh viện Đa khoa Quốc tế Vinmec",
                    url: URL(string: "https://www.vinmec.com/vie/bai-viet/thong-kinh-la-gi-va-co-nguy-hiem-khong-vi")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.de"),
                    host: "Bệnh viện Đa khoa Quốc tế Vinmec",
                    url: URL(string: "https://www.vinmec.com/vie/bai-viet/cac-kien-thuc-tranh-thai-co-ban-ai-cung-nen-nam-vung-vi")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.menopause.de"),
                    host: "Cục Dân số, Bộ Y tế",
                    url: URL(string: "https://vnpa.moh.gov.vn/storage/magazine/2024/12/2281734488751-3793-qdbsigned.pdf")!
                )
            ]
        }

        if languageCode == "th" {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.en"),
                    host: "คณะแพทยศาสตร์ศิริราชพยาบาล มหาวิทยาลัยมหิดล",
                    url: URL(string: "https://www.si.mahidol.ac.th/metc/met/th/job/MenstrualHygieneMaterial/index.html")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.en"),
                    host: "โรงพยาบาลศิริราช ปิยมหาราชการุณย์",
                    url: URL(string: "https://www.siphhospital.com/th/news/article/share/premenstrual-syndrome")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.en"),
                    host: "คณะแพทยศาสตร์ศิริราชพยาบาล มหาวิทยาลัยมหิดล",
                    url: URL(string: "https://www.si.mahidol.ac.th/TH/healthdetail.asp?aid=1209")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.de"),
                    host: "กรมอนามัย กระทรวงสาธารณสุข",
                    url: URL(string: "https://multimedia.anamai.moph.go.th/infographics/which-birth-control-method-is-right-for-you/")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.menopause.de"),
                    host: "คณะแพทยศาสตร์ศิริราชพยาบาล มหาวิทยาลัยมหิดล",
                    url: URL(string: "https://si.mahidol.ac.th/th/healthdetail.asp?aid=1276")!
                )
            ]
        }

        if languageCode == "uk" {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.en"),
                    host: "Центр громадського здоров’я України",
                    url: URL(string: "https://phc.org.ua/news/mi-misyachni-ne-ci-dni-28-travnya-den-menstrualnoi-gigieni")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.en"),
                    host: "МОЗ України",
                    url: URL(string: "https://guidelines.moz.gov.ua/documents/3370")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.en"),
                    host: "МОЗ України",
                    url: URL(string: "https://guidelines.moz.gov.ua/documents/3369")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.ru"),
                    host: "МОЗ України",
                    url: URL(string: "https://guidelines.moz.gov.ua/documents/3397")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.menopause.de"),
                    host: "МОЗ України",
                    url: URL(string: "https://guidelines.moz.gov.ua/documents/5208")!
                )
            ]
        }

        if languageCode == "hi" {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.en"),
                    host: "विकासपीडिया",
                    url: URL(string: "https://hi.vikaspedia.in/viewcontent/health/women-health/92e93e93993593e930940-938947-93892e94d92c90292793f924-93892e93894d92f93e90f902/93894d92494d930940-915947-936930940930-915940-93091a92893e-914930-92e93e93993593e930940")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.en"),
                    host: "राष्ट्रीय स्वास्थ्य मिशन",
                    url: URL(string: "https://nhm.gov.in/New_Updates_2018/NHM_Components/RMNCHA/AH/Training_Materials/Training-and-Resource-Material-Hindi.pdf")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.en"),
                    host: "विकासपीडिया",
                    url: URL(string: "https://health.vikaspedia.in/viewcontent/health/women-health/92e93e93993593e930940-938947-93892e94d92c90292793f924-93892e93894d92f93e90f902/90693593694d92f915-91c93e92891593e93093f92f93e902?lgn=hi")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.en"),
                    host: "राष्ट्रीय स्वास्थ्य मिशन",
                    url: URL(string: "https://nhm.gov.in/images/pdf/programmes/family-planing/guidelines/Asha-Booklet-Hindi.pdf")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.menopause.de"),
                    host: "केंद्रीय स्वास्थ्य शिक्षा ब्यूरो",
                    url: URL(string: "https://cheb.mohfw.gov.in/cheb-library")!
                )
            ]
        }

        if languageCode == "ko" {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.en"),
                    host: "MSD 매뉴얼 일반인용",
                    url: URL(string: "https://www.msdmanuals.com/ko/home/%EC%97%AC%EC%84%B1-%EA%B1%B4%EA%B0%95-%EB%AC%B8%EC%A0%9C/%EC%97%AC%EC%84%B1-%EC%83%9D%EC%8B%9D%EA%B3%84-%EC%83%9D%EB%AC%BC%ED%95%99/%EC%9B%94%EA%B2%BD-%EC%A3%BC%EA%B8%B0")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.en"),
                    host: "MSD 매뉴얼 일반인용",
                    url: URL(string: "https://www.msdmanuals.com/ko/home/%EC%97%AC%EC%84%B1-%EA%B1%B4%EA%B0%95-%EB%AC%B8%EC%A0%9C/%EC%9B%94%EA%B2%BD-%EC%9E%A5%EC%95%A0-%EB%B0%8F-%EB%B9%84%EC%A0%95%EC%83%81-%EC%9E%90%EA%B6%81-%EC%B6%9C%ED%98%88/%EC%9B%94%EA%B2%BD-%EC%A0%84-%EC%A6%9D%ED%9B%84%EA%B5%B0-pms")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.en"),
                    host: "MSD 매뉴얼 일반인용",
                    url: URL(string: "https://www.msdmanuals.com/ko/home/%EC%97%AC%EC%84%B1-%EA%B1%B4%EA%B0%95-%EB%AC%B8%EC%A0%9C/%EC%9B%94%EA%B2%BD-%EC%9E%A5%EC%95%A0-%EB%B0%8F-%EB%B9%84%EC%A0%95%EC%83%81-%EC%9E%90%EA%B6%81-%EC%B6%9C%ED%98%88/%EC%9B%94%EA%B2%BD-%EC%A4%91-%EA%B2%BD%EB%A0%A8")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.ru"),
                    host: "MSD 매뉴얼 일반인용",
                    url: URL(string: "https://www.msdmanuals.com/ko/home/%EC%97%AC%EC%84%B1-%EA%B1%B4%EA%B0%95-%EB%AC%B8%EC%A0%9C/%EA%B0%80%EC%A1%B1-%EA%B3%84%ED%9A%8D/%ED%98%B8%EB%A5%B4%EB%AA%AC-%EC%A1%B0%EC%A0%88%EB%B2%95")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.menopause.de"),
                    host: "MSD 매뉴얼 일반인용",
                    url: URL(string: "https://www.msdmanuals.com/ko/home/%EC%97%AC%EC%84%B1-%EA%B1%B4%EA%B0%95-%EB%AC%B8%EC%A0%9C/%ED%8F%90%EA%B2%BD/%ED%8F%90%EA%B2%BD")!
                )
            ]
        }

        if languageCode == "de" {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.de"),
                    host: "familienplanung.de · BIÖG",
                    url: URL(string: "https://www.familienplanung.de/kinderwunsch/fruchtbarkeit-geschlechtsorgane/menstruationszyklus/")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.de"),
                    host: "gesundheitsinformation.de · IQWiG",
                    url: URL(string: "https://www.gesundheitsinformation.de/praemenstruelles-syndrom-pms.html")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.de"),
                    host: "gesundheitsinformation.de · IQWiG",
                    url: URL(string: "https://www.gesundheitsinformation.de/regelschmerzen.html")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.de"),
                    host: "familienplanung.de · BIÖG",
                    url: URL(string: "https://www.familienplanung.de/verhuetung/welche-verhuetung-passt-zu-mir/")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.menopause.de"),
                    host: "gesund.bund.de",
                    url: URL(string: "https://gesund.bund.de/wechseljahre")!
                )
            ]
        }

        if languageCode == "fr" {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.fr"),
                    host: "questionsexualite.fr · Santé publique France",
                    url: URL(string: "https://www.questionsexualite.fr/comprendre-la-conception-et-la-grossesse/la-sexualite-reproductive/le-cycle-menstruel")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.fr"),
                    host: "msdmanuals.com",
                    url: URL(string: "https://www.msdmanuals.com/fr/accueil/probl%C3%A8mes-de-sant%C3%A9-de-la-femme/troubles-menstruels-et-saignements-ut%C3%A9rins-anormaux/syndrome-pr%C3%A9menstruel-spm")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.fr"),
                    host: "ameli.fr · Assurance Maladie",
                    url: URL(string: "https://www.ameli.fr/assure/sante/themes/regles-douloureuses/douleurs-regles")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.fr"),
                    host: "ameli.fr · Assurance Maladie",
                    url: URL(string: "https://www.ameli.fr/assure/sante/themes/contraception/methodes-contraception-hormonale")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.variation.fr"),
                    host: "ameli.fr · Assurance Maladie",
                    url: URL(string: "https://www.ameli.fr/assure/sante/themes/menopause/perimenopause-premenopause-symptomes-et-contraception")!
                )
            ]
        }

        if languageCode == "es" {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.es"),
                    host: "MedlinePlus · NLM",
                    url: URL(string: "https://medlineplus.gov/spanish/menstruation.html")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.es"),
                    host: "MedlinePlus · NLM",
                    url: URL(string: "https://medlineplus.gov/spanish/premenstrualsyndrome.html")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.es"),
                    host: "MedlinePlus · NLM",
                    url: URL(string: "https://medlineplus.gov/spanish/periodpain.html")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.es"),
                    host: "MedlinePlus · NLM",
                    url: URL(string: "https://medlineplus.gov/spanish/birthcontrol.html")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.variation.es"),
                    host: "MedlinePlus · NLM",
                    url: URL(string: "https://medlineplus.gov/spanish/menopause.html")!
                )
            ]
        }

        if languageCode == "it" {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.it"),
                    host: "Manuale MSD",
                    url: URL(string: "https://www.msdmanuals.com/it/casa/i-fatti-in-breve-problemi-di-salute-delle-donne/biologia-dell-apparato-riproduttivo-femminile/ciclo-mestruale")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.it"),
                    host: "Manuale MSD",
                    url: URL(string: "https://www.msdmanuals.com/it/casa/problemi-di-salute-delle-donne/disturbi-mestruali-e-sanguinamento-uterino-anomalo/sindrome-premestruale-spm")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.it"),
                    host: "Manuale MSD",
                    url: URL(string: "https://www.msdmanuals.com/it/casa/problemi-di-salute-delle-donne/disturbi-mestruali-e-sanguinamento-uterino-anomalo/crampi-mestruali")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.it"),
                    host: "Manuale MSD",
                    url: URL(string: "https://www.msdmanuals.com/it/casa/problemi-di-salute-delle-donne/pianificazione-familiare/metodi-contraccettivi-ormonali")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.variation.it"),
                    host: "Manuale MSD",
                    url: URL(string: "https://www.msdmanuals.com/it/casa/problemi-di-salute-delle-donne/menopausa/menopausa")!
                )
            ]
        }

        if languageCode == "ru" {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.ru"),
                    host: "Справочник MSD",
                    url: URL(string: "https://www.msdmanuals.com/ru/home/проблемы-со-здоровьем-у-женщин/строение-и-функции-женской-репродуктивной-системы/менструальный-цикл")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.ru"),
                    host: "Справочник MSD",
                    url: URL(string: "https://www.msdmanuals.com/ru/home/проблемы-со-здоровьем-у-женщин/нарушения-менструального-цикла-и-патологическое-маточное-кровотечение/предменструальный-синдром-пмс")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.ru"),
                    host: "Справочник MSD",
                    url: URL(string: "https://www.msdmanuals.com/ru/home/проблемы-со-здоровьем-у-женщин/нарушения-менструального-цикла-и-патологическое-маточное-кровотечение/менструальные-спазмы")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.ru"),
                    host: "Справочник MSD",
                    url: URL(string: "https://www.msdmanuals.com/ru/home/проблемы-со-здоровьем-у-женщин/планирование-семьи/гормональные-методы-контрацепции")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.variation.ru"),
                    host: "Справочник MSD",
                    url: URL(string: "https://www.msdmanuals.com/ru/home/проблемы-со-здоровьем-у-женщин/менопауза/менопауза")!
                )
            ]
        }

        if languageCode == "ar" {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.ar"),
                    host: "منظمة الصحة العالمية",
                    url: URL(string: "https://www.who.int/ar/news-room/fact-sheets/detail/menstrual-health")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.ar"),
                    host: "دليل MSD",
                    url: URL(string: "https://www.msdmanuals.com/ar/home/%D9%82%D8%B6%D8%A7%D9%8A%D8%A7-%D8%B5%D8%AD%D9%91%D9%8E%D8%A9-%D8%A7%D9%84%D9%85%D8%B1%D8%A3%D8%A9/%D8%A7%D8%B6%D8%B7%D8%B1%D8%A7%D8%A8%D8%A7%D8%AA-%D8%A7%D9%84%D8%AF%D9%88%D8%B1%D8%A9-%D8%A7%D9%84%D8%B4%D9%87%D8%B1%D9%8A%D8%A9-%D9%88%D8%A7%D9%84%D9%86%D8%B2%D9%81-%D8%A7%D9%84%D8%B1%D8%AD%D9%85%D9%8A-%D8%BA%D9%8A%D8%B1-%D8%A7%D9%84%D8%B7%D9%91%D9%8E%D8%A8%D9%8A%D8%B9%D9%8A/%D8%A7%D9%84%D9%85%D8%AA%D9%84%D8%A7%D8%B2%D9%85%D8%A9-%D8%A7%D9%84%D8%B3%D8%A7%D8%A8%D9%82%D8%A9-%D9%84%D9%84%D8%B7%D9%85%D8%AB")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.ar"),
                    host: "دليل MSD",
                    url: URL(string: "https://www.msdmanuals.com/ar/home/%D9%82%D8%B6%D8%A7%D9%8A%D8%A7-%D8%B5%D8%AD%D9%91%D9%8E%D8%A9-%D8%A7%D9%84%D9%85%D8%B1%D8%A3%D8%A9/%D8%A7%D8%B6%D8%B7%D8%B1%D8%A7%D8%A8%D8%A7%D8%AA-%D8%A7%D9%84%D8%AF%D9%88%D8%B1%D8%A9-%D8%A7%D9%84%D8%B4%D9%87%D8%B1%D9%8A%D8%A9-%D9%88%D8%A7%D9%84%D9%86%D8%B2%D9%81-%D8%A7%D9%84%D8%B1%D8%AD%D9%85%D9%8A-%D8%BA%D9%8A%D8%B1-%D8%A7%D9%84%D8%B7%D9%91%D9%8E%D8%A8%D9%8A%D8%B9%D9%8A/%D8%A7%D9%84%D8%AA%D8%B4%D9%86%D9%91%D9%8F%D8%AC%D8%A7%D8%AA-%D8%A7%D9%84%D8%AD%D9%8A%D8%B6%D9%8A%D8%A9")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.ar"),
                    host: "منظمة الصحة العالمية",
                    url: URL(string: "https://www.who.int/ar/news-room/fact-sheets/detail/oral-contraceptives")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.variation.ar"),
                    host: "منظمة الصحة العالمية",
                    url: URL(string: "https://www.who.int/ar/news-room/fact-sheets/detail/menopause")!
                )
            ]
        }

        if languageCode == "pt" {
            return [
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.basics"),
                    title: String(localized: "cycle.education.source.cycle.ptBR"),
                    host: "Manual MSD",
                    url: URL(string: "https://www.msdmanuals.com/pt/casa/problemas-de-sa%C3%BAde-feminina/biologia-do-sistema-reprodutor-feminino/ciclo-menstrual")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pms"),
                    title: String(localized: "cycle.education.source.pms.ptBR"),
                    host: "Manual MSD",
                    url: URL(string: "https://www.msdmanuals.com/pt/casa/problemas-de-sa%C3%BAde-feminina/dist%C3%BArbios-menstruais-e-sangramento-uteino-an%C3%B4malo/tens%C3%A3o-pr%C3%A9-menstrual-tpm")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.pain"),
                    title: String(localized: "cycle.education.source.pain.ptBR"),
                    host: "Manual MSD",
                    url: URL(string: "https://www.msdmanuals.com/pt/casa/problemas-de-sa%C3%BAde-feminina/dist%C3%BArbios-menstruais-e-sangramento-uteino-an%C3%B4malo/c%C3%B3licas-menstruais")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.contraception"),
                    title: String(localized: "cycle.education.source.contraception.ptBR"),
                    host: "Ministério da Saúde",
                    url: URL(string: "https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/s/saude-da-mulher/saude-sexual-e-reprodutiva/contracepcao")!
                ),
                EducationSource(
                    topic: String(localized: "cycle.education.source.topic.variation"),
                    title: String(localized: "cycle.education.source.variation.ptBR"),
                    host: "Manual MSD",
                    url: URL(string: "https://www.msdmanuals.com/pt/casa/problemas-de-sa%C3%BAde-feminina/menopausa/menopausa")!
                )
            ]
        }

        return [
            EducationSource(
                topic: String(localized: "cycle.education.source.topic.basics"),
                title: String(localized: "cycle.education.source.cycle.en"),
                host: "acog.org",
                url: URL(string: "https://www.acog.org/womens-health/infographics/the-menstrual-cycle")!
            ),
            EducationSource(
                topic: String(localized: "cycle.education.source.topic.pms"),
                title: String(localized: "cycle.education.source.pms.en"),
                host: "acog.org",
                url: URL(string: "https://www.acog.org/womens-health/faqs/premenstrual-syndrome")!
            ),
            EducationSource(
                topic: String(localized: "cycle.education.source.topic.pain"),
                title: String(localized: "cycle.education.source.pain.en"),
                host: "acog.org",
                url: URL(string: "https://www.acog.org/womens-health/faqs/painful-periods")!
            ),
            EducationSource(
                topic: String(localized: "cycle.education.source.topic.contraception"),
                title: String(localized: "cycle.education.source.contraception.en"),
                host: "nhs.uk",
                url: URL(string: "https://www.nhs.uk/contraception/choosing-contraception/effects-on-periods/")!
            ),
            EducationSource(
                topic: String(localized: "cycle.education.source.topic.variation"),
                title: String(localized: "cycle.education.source.variation.en"),
                host: "nhs.uk",
                url: URL(string: "https://www.nhs.uk/symptoms/irregular-periods/")!
            )
        ]
    }
}

private struct EducationTextCard: View {
    var title: LocalizedStringResource
    var summary: LocalizedStringResource
    var bodyText: LocalizedStringResource
    var icon: String
    var tint: Color

    var bodyView: some View {
        IOSCard {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(tint)

            Text(summary)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Text(bodyText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var body: some View {
        bodyView
    }
}

private struct EducationPhaseCard: View {
    var section: CycleSection
    var text: LocalizedStringResource

    private var content: CycleSectionContent {
        CycleContentRepository.content(for: section)
    }

    var body: some View {
        IOSCard {
            Label(content.title, systemImage: section.icon)
                .font(.headline)
                .foregroundStyle(section.tint)
            Text(content.biologicalPhase)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct EducationSource: Identifiable {
    var id: URL { url }
    var topic: String
    var title: String
    var host: String
    var url: URL
}

struct CycleEducationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CycleEducationView()
        }
        .previewDisplayName("Zyklus verstehen")
    }
}
