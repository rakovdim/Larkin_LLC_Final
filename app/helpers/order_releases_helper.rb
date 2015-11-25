#todo refactor
module OrderReleasesHelper
  def has_errors
    @order_releases ||= [@order_release]
    @order_releases.each do |order_release|
      if order_release.errors.any?
        return true
      end
    end
    false
  end
end
