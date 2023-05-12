//
//  TittleHeader.swift
//  RapsodoApp
//
//  Created by Ömer Faruk Başaran on 6.05.2023.
//

import Foundation
import UIKit

class HeaderView: UICollectionReusableView {
    let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // header görünümünü yapılandırma
        titleLabel.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        titleLabel.textAlignment = .left
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        titleLabel.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    
        addSubview(titleLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
