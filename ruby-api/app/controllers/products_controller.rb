# frozen_string_literal: true

class ProductsController < ApplicationController
  def get
    products = []
    Product.where(active: true).order(:id).each do |p|
      prod = p.attributes
      # prod[:mints] = ProductMintList.where(name: p.mint_list_name).map(&:mint) if p.gated
      products << prod
    end

    render json: { status: 'success', products: products }
  end

  def product
    product = Product.find_by(uuid: params[:uuid])
    prod = product.attributes
    # prod[:mints] = ProductMintList.where(name: product.mint_list_name).map(&:mint) if product.gated

    render json: { status: 'success', product: prod, collection: product.product_collection.uuid,
                   wallet: product.product_collection.wallet }
  end

  def collections
    collections = ProductCollection.all.order(:id)
    render json: { status: 'success', collections: collections }
  end

  def collection
    collection = ProductCollection.find_by(uuid: params[:uuid])
    render json: { status: 'success', collection: collection }
  end

  def products
    collection = ProductCollection.find_by(uuid: params[:uuid])
    products = []
    Product.where(active: true, product_collection_id: collection.id).order(:id).each do |p|
      prod = p.attributes
      # prod[:mints] = ProductMintList.where(name: p.mint_list_name).map(&:mint) if p.gated
      products << prod
    end

    render json: { status: 'success', products: products }
  end
end
