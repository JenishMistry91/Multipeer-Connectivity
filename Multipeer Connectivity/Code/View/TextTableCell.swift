//
//  TextTableCell.swift
//  Multipeer Connectivity
//
//  Created by Jenish Mistry on 01/08/20.
//  Copyright © 2020 Jenish Mistry. All rights reserved.
//

import UIKit

class TextTableCell: UITableViewCell {

    // MARK :- Attributes -
    @IBOutlet weak var lblTextContent: UILabel!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnDelete: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - Helper Methods -
    
    func setTextData(text: String) {
        self.lblTextContent.text = text
    }
    
}
