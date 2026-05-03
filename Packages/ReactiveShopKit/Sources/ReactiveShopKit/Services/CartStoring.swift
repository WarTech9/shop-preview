import Foundation

@MainActor
public protocol CartStoring: AnyObject {
    var cart: Cart { get }
    func add(_ variant: ProductVariant, of product: Product) throws
    func setQuantity(_ quantity: Int, for lineId: String)
}
