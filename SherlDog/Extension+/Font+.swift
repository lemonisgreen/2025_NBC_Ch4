//
//  Font+.swift
//  SherlDog
//
//  Created by JIN LEE on 6/4/25.
//

import UIKit

extension UIFont {
    // Pretendard 웨이트별 이름 매핑
    static func pretendard(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let familyName = "Pretendard"
        var weightString: String
        
        switch weight {
        case .bold:         weightString = "Bold"
        case .medium:       weightString = "Medium"
        case .regular:      weightString = "Regular"
        case .semibold:     weightString = "SemiBold"
        default:            weightString = "Regular"
        }
        
        let fontName = "\(familyName)-\(weightString)"
        return UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size, weight: weight)
    }
    
    // MARK: Highlight -
    static var highlight1: UIFont {
        pretendard(ofSize: 28, weight: .bold)
    }
    static var highlight2: UIFont {
        pretendard(ofSize: 24, weight: .bold)
    }
    static var highlight3: UIFont {
        pretendard(ofSize: 20, weight: .bold)
    }
    static var highlight4: UIFont {
        pretendard(ofSize: 18, weight: .bold)
    }
    
    // MARK: Title -
    static var title1: UIFont {
        pretendard(ofSize: 20, weight: .semibold)
    }
    static var title2: UIFont {
        pretendard(ofSize: 20, weight: .regular)
    }
    static var title3: UIFont {
        pretendard(ofSize: 18, weight: .regular)
    }
    static var title4: UIFont {
        pretendard(ofSize: 12, weight: .regular)
    }
    
    // MARK: Body -
    static var body1: UIFont {
        pretendard(ofSize: 16, weight: .semibold)
    }
    static var body2: UIFont {
        pretendard(ofSize: 16, weight: .medium)
    }
    static var body3: UIFont {
        pretendard(ofSize: 16, weight: .regular)
    }
    static var body4: UIFont {
        pretendard(ofSize: 14, weight: .semibold)
    }
    static var body5: UIFont {
        pretendard(ofSize: 14, weight: .medium)
    }
    static var body6: UIFont {
        pretendard(ofSize: 14, weight: .regular)
    }
    
    // MARK: Etc -
    static var small: UIFont {
        pretendard(ofSize: 14, weight: .regular)
    }
    static var footnote: UIFont {
        pretendard(ofSize: 12, weight: .regular)
    }
    static var alert1: UIFont {
        pretendard(ofSize: 12, weight: .semibold)
    }
    static var alert2: UIFont {
        pretendard(ofSize: 12, weight: .regular)
    }
    
    static var cardTitle: UIFont {
        return UIFont(name: "EF_jejudoldam(OTF)", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold)
    }
    
    /* 사용 예시:
     
     label.font = UIFont.highlight1
     label.font = UIFont.body
     label.font = UIFont.subhead
     label.font = UIFont.button
     
     */
}
