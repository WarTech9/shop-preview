import SwiftUI
import ReactivShopKit

struct CartView: View {
    @State private var viewModel: CartViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CartViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEmpty {
                    CartEmptyState(onBrowse: { dismiss() })
                } else {
                    List {
                        ForEach(viewModel.lines) { line in
                            CartLineRow(line: line) { newQuantity in
                                viewModel.setQuantity(newQuantity, for: line.id)
                            }
                        }
                        .onDelete { indices in
                            for index in indices {
                                viewModel.remove(viewModel.lines[index].id)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                    .safeAreaInset(edge: .bottom) {
                        CartTotalsFooter(
                            itemCount: viewModel.itemCount,
                            subtotal: viewModel.subtotal,
                            total: viewModel.total
                        )
                    }
                }
            }
            .navigationTitle("Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
