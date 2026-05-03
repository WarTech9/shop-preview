import Foundation

/// Maps a wire-format `ProductDTO` to a Domain `Product`.
/// Returns nil if any invariant fails: malformed price, no variants, all variants malformed.
/// Bad images are silently dropped (Domain allows empty image arrays).
func makeProduct(_ dto: ProductDTO) -> Product? {
    guard let priceRange = makePriceRange(dto.priceRange) else { return nil }
    let compareAt = dto.compareAtPriceRange.flatMap(makePriceRange)

    let variants = dto.variants.compactMap(makeVariant)
    guard !variants.isEmpty else { return nil }

    let images = dto.images.compactMap(makeImage)
    let options = dto.options.map(makeOption)

    return Product(
        id: dto.id,
        handle: dto.handle,
        title: dto.title,
        vendor: dto.vendor,
        description: dto.description,
        isAvailable: dto.availableForSale,
        priceRange: priceRange,
        compareAtPriceRange: compareAt,
        images: images,
        options: options,
        variants: variants
    )
}

private func makeVariant(_ dto: VariantDTO) -> ProductVariant? {
    guard let price = makeMoney(dto.price) else { return nil }
    let compareAt = dto.compareAtPrice.flatMap(makeMoney)
    let selected = dto.selectedOptions.map { SelectedOption(name: $0.name, value: $0.value) }

    return ProductVariant(
        id: dto.id,
        title: dto.title,
        isAvailable: dto.availableForSale,
        price: price,
        compareAtPrice: compareAt,
        selectedOptions: selected,
        imageId: dto.image?.id
    )
}

private func makeMoney(_ dto: MoneyDTO) -> Money? {
    guard let amount = Decimal(string: dto.amount) else { return nil }
    return Money(amount: amount, currencyCode: dto.currencyCode)
}

private func makePriceRange(_ dto: PriceRangeDTO) -> PriceRange? {
    guard let min = makeMoney(dto.minVariantPrice),
          let max = makeMoney(dto.maxVariantPrice) else { return nil }
    return PriceRange(min: min, max: max)
}

private func makeImage(_ dto: ImageDTO) -> ProductImage? {
    guard let url = URL(string: dto.url) else { return nil }
    return ProductImage(id: dto.id, url: url)
}

private func makeOption(_ dto: OptionDTO) -> ProductOption {
    ProductOption(id: dto.id, name: dto.name, values: dto.values)
}
