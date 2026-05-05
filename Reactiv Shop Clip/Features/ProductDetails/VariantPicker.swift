import SwiftUI
import ReactivShopKit

struct VariantPicker: View {
    let option: ProductOption
    let availableValues: Set<String>
    let selectedValue: String?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(option.name)
                .font(.headline)
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(option.values, id: \.self) { value in
                        chip(for: value)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func chip(for value: String) -> some View {
        let isSelected = selectedValue == value
        let isAvailable = availableValues.contains(value)

        return Button {
            onSelect(value)
        } label: {
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 16)
                .frame(minWidth: 44, minHeight: 44)
                .background {
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.systemGray6))
                }
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color(.separator), lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
        .opacity(isAvailable ? 1.0 : 0.4)
        .disabled(!isAvailable)
        .accessibilityLabel(value)
        .accessibilityValue(isSelected ? "selected" : "")
        .accessibilityHint(isAvailable ? "" : "Out of stock")
    }
}
