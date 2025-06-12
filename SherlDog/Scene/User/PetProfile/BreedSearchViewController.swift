//
//  BreedSearchViewController.swift
//  SherlDog
//
//  Created by 최영락 on 6/10/25.
//

import UIKit
import SnapKit

class BreedSearchViewController: UIViewController {
    
    // MARK: - Constants
    // UI에서 사용할 고정값들 정의
    private struct Constants {
        static let titleFontSize: CGFloat = 20
        static let searchFieldHeight: CGFloat = 40
        static let closeButtonSize: CGFloat = 24
        static let imageSize: CGFloat = 80
        static let padding: CGFloat = 20
        static let cellHeight: CGFloat = 60
    }
    
    // MARK: - Properties
    private var allBreeds: [String] = [
        "골든 리트리버", "래브라도 리트리버", "저먼 셰퍼드", "불독", "비글",
        "푸들", "로트와일러", "요크셔 테리어", "닥스훈트", "시베리안 허스키",
        "보더 콜리", "복서", "그레이트 데인", "시츄", "보스턴 테리어",
        "폼피츠", "치와와", "말티즈", "코기", "진돗개"
    ]
    
    // 검색 결과 필터링된 견종 리스트
    private var filteredBreeds: [String] = []
    // 검색 중인지 여부
    private var isSearching: Bool = false
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "견종 선택하기"
        label.font = .highlight3
        label.textColor = .textPrimary
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .textPrimary
        return button
    }()
    
    private let searchTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "검색"
        tf.backgroundColor = .gray100
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.gray200.cgColor
        tf.layer.cornerRadius = 8
        tf.font = .systemFont(ofSize: 16)
        return tf
    }()
    
    // 결과 없을 때 이미지
    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "sherlDog")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemGray3
        iv.alpha = 1
        return iv
    }()
    
    // 결과 없을 때 문구
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "어떤 견종을 찾으시나요?"
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - No Results Components
    
    // 검색 결과 없음 관련 뷰들 ( 숨김 기본 )
    private let noResultsImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "noResultDog") // 검색 결과 없음 이미지
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemGray3
        iv.isHidden = true
        return iv
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "검색 결과가 없습니다"
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private let noResultsDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "원하시는 견종이 검색결과에 없다면\n직접 견종을 추가해보세요"
        label.textColor = .systemGray2
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.isHidden = true
        return label
    }()
    
    private let addBreedButton: UIButton = {
        let button = UIButton()
        button.setTitle("견종 직접 추가", for: .normal)
        button.setTitleColor(.keycolorPrimary1, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .clear
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.keycolorPrimary1.cgColor
        button.layer.cornerRadius = 8
        button.isHidden = true
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.backgroundColor = .clear
        // 구분선
        tv.separatorStyle = .singleLine
        tv.separatorColor = UIColor.gray200
        tv.register(BreedTableViewCell.self, forCellReuseIdentifier: "BreedCell")
        tv.isHidden = true
        //테이블뷰를 스크롤할때 키보드가 자동으로 내려감.
        tv.keyboardDismissMode = .onDrag
        return tv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupConstraints()
        setupSearchTextField()
    }
    
    // MARK: - Setup
    private func setupUI() {
        searchTextField.setLeftPaddingIcon(systemName: "magnifyingglass")
        
        [titleLabel, closeButton, searchTextField, emptyImageView, emptyLabel,
         noResultsImageView, noResultsLabel, noResultsDescriptionLabel, addBreedButton, tableView].forEach {
            view.addSubview($0)
        }
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        addBreedButton.addTarget(self, action: #selector(addBreedButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.padding)
            $0.leading.equalToSuperview().inset(Constants.padding)
        }
        
        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(Constants.padding)
            $0.size.equalTo(Constants.closeButtonSize)
        }
        
        searchTextField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(Constants.padding)
            $0.height.equalTo(Constants.searchFieldHeight)
        }
        
        emptyImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(searchTextField.snp.bottom).offset(150)
            $0.size.equalTo(Constants.imageSize)
        }
        
        emptyLabel.snp.makeConstraints {
            $0.top.equalTo(emptyImageView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchTextField.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        // No Results Components Constraints
        noResultsImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(searchTextField.snp.bottom).offset(120)
            $0.size.equalTo(Constants.imageSize)
        }
        
        noResultsLabel.snp.makeConstraints {
            $0.top.equalTo(noResultsImageView.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        
        noResultsDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(noResultsLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(40)
        }
        
        addBreedButton.snp.makeConstraints {
            $0.top.equalTo(noResultsDescriptionLabel.snp.bottom).offset(24)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(140)
            $0.height.equalTo(40)
        }
    }
    
    /// 검색창에 텍스트 변화 감지 및 델리게이트 설정

    private func setupSearchTextField() {
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        searchTextField.delegate = self
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func addBreedButtonTapped() {
        // 검색창에 입력된 문자열을 앞 뒤 공백 제거 후 가져옴
        // 공백만 입력했거나 아무것도 입력하지 않으면 함수 종료.
        guard let searchText = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !searchText.isEmpty else { return }
        
        // 견종을 allBreeds 배열에 추가
        allBreeds.append(searchText)
        
        // 선택된 견종 처리 (여기서 delegate나 completion handler 호출 가능)
        print("직접 추가된 견종: \(searchText)")
        
        // 화면 닫기
        dismiss(animated: true)
    }
    
    @objc private func searchTextChanged() {
        // 입력된 텍스트가 있는지 확인
        guard let searchText = searchTextField.text else { return }
        
        // 빈 문자열이면 빈 상태 보여주고, 아니면 검색 결과 보여줌
        if searchText.isEmpty {
            showEmptyState()
        } else {
            showSearchResults(for: searchText)
        }
    }
    
    // MARK: - Private Methods
    private func showEmptyState() {
        // 검색 중이 아님.
        isSearching = false
        
        // 모든 상태 초기화
        hideAllStates()
        
        // 빈 상태 표시
        emptyImageView.isHidden = false
        emptyLabel.isHidden = false
        
        // 부드러운 애니메이션 (사라짐)
        UIView.animate(withDuration: 0.3) {
            self.emptyImageView.alpha = 1
            self.emptyLabel.alpha = 1
        }
    }
    
    private func showSearchResults(for searchText: String) {
        isSearching = true
        
        // 필터링 로직 입력된 문자열을 포함하는 견종만 필터링
        filteredBreeds = allBreeds.filter { breed in
            breed.localizedCaseInsensitiveContains(searchText)
        }
        
        // UI 업데이트
        hideAllStates()
        
        if filteredBreeds.isEmpty {
            // 검색 결과 없음 상태
            showNoResultsState()
        } else {
            // 검색 결과 있음 상태
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
    
    // 검색 결과 없음 상태
    private func showNoResultsState() {
        noResultsImageView.isHidden = false
        noResultsLabel.isHidden = false
        noResultsDescriptionLabel.isHidden = false
        addBreedButton.isHidden = false
        
        // 부드러운 애니메이션 효과 ㅋㅋ
        UIView.animate(withDuration: 0.3) {
            self.noResultsImageView.alpha = 1
            self.noResultsLabel.alpha = 1
            self.noResultsDescriptionLabel.alpha = 1
            self.addBreedButton.alpha = 1
        }
    }
    
    private func hideAllStates() {
        // 빈 상태 숨김
        emptyImageView.isHidden = true
        emptyLabel.isHidden = true
        emptyImageView.alpha = 0
        emptyLabel.alpha = 0
        
        // 검색 결과 없음 상태 숨김
        noResultsImageView.isHidden = true
        noResultsLabel.isHidden = true
        noResultsDescriptionLabel.isHidden = true
        addBreedButton.isHidden = true
        noResultsImageView.alpha = 0
        noResultsLabel.alpha = 0
        noResultsDescriptionLabel.alpha = 0
        addBreedButton.alpha = 0
        
        // 테이블뷰 숨김
        tableView.isHidden = true
    }
}

// MARK: - UITableViewDataSource
extension BreedSearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // isSearching이 true 일때 : false 일때
        return isSearching ? filteredBreeds.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BreedCell", for: indexPath) as! BreedTableViewCell
        let breed = filteredBreeds[indexPath.row]
        cell.configure(with: breed)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension BreedSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedBreed = filteredBreeds[indexPath.row]
        // 선택된 견종 처리
        print("선택된 견종: \(selectedBreed)")
        dismiss(animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension BreedSearchViewController: UITextFieldDelegate {
    // 키보드 리턴키를 입력했을때 키보드 창 내려감.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UITextField Extension
extension UITextField {
    func setLeftPaddingIcon(systemName: String) {
        let icon = UIImageView(image: UIImage(systemName: systemName))
        icon.tintColor = .systemGray
        icon.contentMode = .scaleAspectFit
        
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        icon.frame = CGRect(x: 8, y: 8, width: 20, height: 20)
        container.addSubview(icon)
        
        self.leftView = container
        self.leftViewMode = .always
    }
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}
