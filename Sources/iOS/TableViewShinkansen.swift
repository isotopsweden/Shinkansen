//
//  TableViewShinkansen.swift
//  Shinkansen iOS
//
//  Created by Simon Jarbrant on 2019-02-19.
//

import UIKit

public class TableViewShinkansen: NSObject {
    public private(set) var sections: [TableViewSection] = []

    public weak var view: UITableView? {
        didSet {
            guard let view = view else { return }
            view.dataSource = self

            for section in sections {
                section.registerCell(in: view)
            }
        }
    }

    public func connectSection(_ section: TableViewSection) {
        section.setConductor(self)

        if let tableView = view {
            section.registerCell(in: tableView)
        }

        sections.append(section)
    }

    public func createSection<DataSource: SectionDataSource, Cell: UITableViewCell>(from dataSource: DataSource, withCellType cellType: Cell.Type, cellConfigurator: @escaping (DataSource.Item, Cell) -> Cell) where Cell: ReusableView {
        let section = TableViewDataSourceSection(dataSource: dataSource, cellConfigurator: { tableView, indexPath in
            let cell = tableView.dequeueReusableCell(ofType: cellType, at: indexPath)
            let item = dataSource.getItem(at: indexPath.row)
            return cellConfigurator(item, cell)
        })

        section.cellRegistrationClosure = { tableView in
            tableView.register(cellType: cellType)
        }

        connectSection(section)
    }

    public func createSection<DataSource: SectionDataSource, Cell: UITableViewCell>(from dataSource: DataSource, withCellType cellType: Cell.Type, cellConfigurator: @escaping (DataSource.Item, Cell) -> Cell) where Cell: ReusableView & NibLoadableView {
        let section = TableViewDataSourceSection(dataSource: dataSource, cellConfigurator: { tableView, indexPath in
            let cell = tableView.dequeueReusableCell(ofType: cellType, at: indexPath)
            let item = dataSource.getItem(at: indexPath.row)
            return cellConfigurator(item, cell)
        })

        section.cellRegistrationClosure = { tableView in
            tableView.register(cellType: cellType)
        }

        connectSection(section)
    }
}

extension TableViewShinkansen: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].tableView(tableView, numberOfRowsInSection: 0)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        return section.tableView(tableView, cellForRowAt: indexPath)
    }
}

extension TableViewShinkansen: SectionConductor {
    public func section(_ section: Section, reloadedItemsAt indices: [Int], dataSourceUpdateClosure: () -> Void) {
        guard let tableView = view,
            let sectionIndex = sections.firstIndex(where: { $0.id == section.id })
            else { return }

        let reloadIndexPaths = indices.map { IndexPath(row: $0, section: sectionIndex) }

        tableView.performBatchUpdates({
            // Allow the data source to update
            dataSourceUpdateClosure()

            // Perform UITableView updates
            tableView.reloadRows(at: reloadIndexPaths, with: .automatic)
        })
    }

    public func section(_ section: Section, performedChanges changes: SectionChange, dataSourceUpdateClosure: () -> Void) {
        guard let tableView = view,
            let sectionIndex = sections.firstIndex(where: { $0.id == section.id })
            else { return }

        let insertIndexPaths = changes.insertions.map { IndexPath(row: $0, section: sectionIndex) }
        let deletionIndexPaths = changes.deletions.map { IndexPath(row: $0, section: sectionIndex) }
        let moveIndexPaths = changes.moves.map { move -> (IndexPath, IndexPath) in
            return (IndexPath(row: move.from, section: sectionIndex), IndexPath(row: move.to, section: sectionIndex))
        }

        tableView.performBatchUpdates({
            // Allow the data source to update
            dataSourceUpdateClosure()

            // Perform UITableView updates
            tableView.deleteRows(at: deletionIndexPaths, with: .automatic)
            tableView.insertRows(at: insertIndexPaths, with: .automatic)

            for move in moveIndexPaths {
                tableView.moveRow(at: move.0, to: move.1)
            }
        })
    }
}