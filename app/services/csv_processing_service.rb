require 'csv'

class CSVProcessingService
  # def upload_releases_from_csv
  #   order_releases =[]
  #   row_num=0
  #   CSV.foreach("/Users/dima/Downloads/task/file.csv") do |row|
  #     row_num=row_num+1
  #     next if (row_num==1)
  #     delivery_date = get_delivery_date row[0]
  #     delivery_shift =get_delivery_shift row[1]
  #     origin_name=row[2]
  #     origin_raw_line =row[3]
  #     origin_city = row[4]
  #     origin_state =row[5]
  #     origin_zip =row[6]
  #     origin_country=row[7]
  #     destination_name=row[8]
  #     destination_raw_line=row[9]
  #     destination_city=row[10]
  #     destination_state=row[11]
  #     destination_zip=row[12]
  #     destination_country=row[13]
  #     phone_number =row[14]
  #     mode =get_mode row[15]
  #     purchase_order_number =row[16]
  #     volume =row[17]
  #     handling_unit_quantity=row[18]
  #     handling_unit_type=get_unit_type row[19]
  #     status = OrderRelease.statuses[:not_planned]
  #     delivery_type = get_delivery_type origin_name
  #
  #     order_releases << OrderRelease.new(:delivery_date => delivery_date,
  #                                        :delivery_shift => delivery_shift,
  #                                        :origin_name => origin_name,
  #                                        :origin_raw_line => origin_raw_line,
  #                                        :origin_city => origin_city,
  #                                        :origin_state => origin_state,
  #                                        :origin_zip => origin_zip,
  #                                        :origin_country => origin_country,
  #                                        :destination_name => destination_name,
  #                                        :destination_raw_line => destination_raw_line,
  #                                        :destination_city => destination_city,
  #                                        :destination_state => destination_state,
  #                                        :destination_zip => destination_zip,
  #                                        :destination_country => destination_country,
  #                                        :phone_number => phone_number,
  #                                        :mode => mode,
  #                                        :purchase_order_number => purchase_order_number,
  #                                        :volume => volume,
  #                                        :handling_unit_quantity => handling_unit_quantity,
  #                                        :handling_unit_type => handling_unit_type,
  #                                        :status => status,
  #                                        :delivery_type => delivery_type)
  #   end
  #   order_releases
  # end
  #
  # private def get_delivery_date (delivery_date_str)
  #   if delivery_date_str.nil?
  #     nil
  #   else
  #     Date.strptime(delivery_date_str, "%m/%d/%Y")
  #   end
  # end
  #
  # private def get_delivery_type (origin_name)
  #   if origin_name =='Larkin LLC'
  #     OrderRelease.delivery_types[:delivery]
  #   else
  #     OrderRelease.delivery_types[:return]
  #   end
  # end
  #
  # private def get_unit_type (str)
  #   case str
  #     when "box"
  #       OrderRelease.handling_unit_types[:box]
  #     else
  #       raise CSVFormatException, 'Incorrect format of handling_unit_type field: '+str
  #   end
  # end
  #
  # private def get_mode (str)
  #   case str
  #     when 'TRUCKLOAD' || 'truckload'
  #       OrderRelease.modes[:truckload]
  #     else
  #       raise CSVFormatException, 'Incorrect format of mode field: '+str
  #   end
  # end
  #
  # private def get_delivery_shift (str)
  #
  #   case str
  #     when nil
  #       OrderRelease.delivery_shifts[:any_time]
  #     when 'M' ||'m'
  #       OrderRelease.delivery_shifts[:morning]
  #     when 'N' ||'n'
  #       OrderRelease.delivery_shifts[:afternoon]
  #     when 'E' ||'e'
  #       OrderRelease.delivery_shifts[:evening]
  #     else
  #       raise CSVFormatException, 'Incorrect format of delivery_shift field: '+str
  #   end
  # end
end