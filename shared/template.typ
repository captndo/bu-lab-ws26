// Reusable style and helpers for laboratory reports.
// Import from a lab report with: #import "../../shared/template.typ": *

#let ink = rgb("193047")
#let accent = rgb("17668A")
#let pale = rgb("F1F5F8")
#let muted = rgb("607082")

#let lab-report(
  title: "Laboratory Report",
  lab-id: "Lab XX",
  course: "Course name",
  author: "Student name",
  student-id: "Student ID",
  // Preferred for group reports: one (name, ID) pair per author.
  // If omitted, the original author/student-id parameters still work.
  authors: none,
  instructor: "Instructor",
  date: "YYYY-MM-DD",
  body,
) = {
  let author-list = if authors == none {
    ((name: author, id: student-id),)
  } else {
    authors
  }

  set page(
    paper: "a4",
    margin: (top: 23mm, bottom: 22mm, left: 24mm, right: 24mm),
    numbering: "1",
    header: context {
      if counter(page).get().first() > 1 {
        set text(size: 8pt, fill: muted)
        [#course #h(1fr) #lab-id]
        line(length: 100%, stroke: 0.4pt + rgb("D8E0E7"))
      }
    },
    footer: context {
      if counter(page).get().first() > 1 {
        set text(size: 8pt, fill: muted)
        [#lab-id #h(1fr) Page #counter(page).display()]
      }
    },
  )
  set text(font: "Libertinus Serif", size: 10.5pt, lang: "en")
  set par(justify: true, leading: 0.65em)
  set heading(numbering: "1.1")
  show heading.where(level: 1): it => {
    set text(font: "Libertinus Serif", size: 15pt, weight: "bold", fill: ink)
    v(8pt)
    it
    v(3pt)
  }
  show heading.where(level: 2): it => {
    set text(font: "Libertinus Serif", size: 11.5pt, weight: "bold", fill: ink)
    v(3pt)
    it
  }
  show figure.caption: set text(size: 9pt)
  show table.cell: set text(size: 9pt)

  // Title page — typographic hierarchy rather than a dense metadata table.
  // The document's content area is 162 mm wide on A4.
  block(width: 100%)[
    #text(font: "Libertinus Serif", size: 10pt, weight: "bold", fill: accent)[LABORATORY REPORT]
    #v(4mm)
    #line(length: 100%, stroke: 1.15pt + accent)
    #v(5mm)
    #text(font: "Libertinus Serif", size: 10pt, fill: muted)[#course]
    #h(1fr)
    #text(font: "Libertinus Serif", size: 10pt, weight: "bold", fill: ink)[#lab-id]
  ]

  v(42mm)

  block(width: 100%)[
    #set par(justify: false)
    #text(font: "Libertinus Serif", size: 25pt, weight: "bold", fill: ink, hyphenate: false)[#title]
    #v(9mm)
    #line(length: 27mm, stroke: 2pt + accent)
  ]

  v(1fr)

  block(width: 100%)[
    #text(font: "Libertinus Serif", size: 9pt, weight: "bold", fill: accent)[PREPARED BY]
    #v(5mm)
    #table(
      columns: (1fr, auto),
      stroke: none,
      inset: (x: 0pt, y: 4pt),
      align: (left, right),
      table.header(
        [#text(font: "Libertinus Serif", size: 8.5pt, fill: muted)[Authors]],
        [#text(font: "Libertinus Serif", size: 8.5pt, fill: muted)[Matriculation no.]],
      ),
      ..author-list.map(person => (
        [#text(font: "Libertinus Serif", size: 11pt, fill: ink)[#person.name]],
        [#text(font: "Libertinus Serif", size: 10pt, fill: ink)[#person.id]],
      )).flatten(),
    )
    #v(7mm)
    #line(length: 100%, stroke: 0.5pt + rgb("D8E0E7"))
    #v(5mm)
    #grid(
      columns: (1fr, 1fr),
      gutter: 10mm,
      [
        #text(font: "Libertinus Serif", size: 8.5pt, fill: muted)[INSTRUCTOR]
        #v(2mm)
        #text(font: "Libertinus Serif", size: 10.5pt, fill: ink)[#instructor]
      ],
      [
        #text(font: "Libertinus Serif", size: 8.5pt, fill: muted)[DATE]
        #v(2mm)
        #text(font: "Libertinus Serif", size: 10.5pt, fill: ink)[#date]
      ],
    )
  ]

  v(19mm)
  pagebreak()

  outline(title: [Contents], depth: 2, indent: 15pt)
  pagebreak()
  body
}

#let note(content) = block(
  width: 100%, fill: pale, radius: 3pt, inset: 10pt,
)[
  #text(fill: muted, size: 9pt)[#content]
]

#let figure-slot(caption-text, height: 34mm) = figure(
  block(
    width: 100%, height: height, radius: 3pt,
    stroke: 0.8pt + rgb("B8C5D1"), fill: rgb("FAFBFC"),
    inset: 9pt,
  )[
    #align(center)[#text(fill: muted, size: 9pt)[Insert image / graph / screenshot here]]
  ],
  caption: [#caption-text],
)

// Construct images in the report so their relative paths belong to that lab.
#let report-figure(body, caption) = figure(body, caption: caption)

#let source-note(content) = text(size: 9pt, fill: muted)[#content]
