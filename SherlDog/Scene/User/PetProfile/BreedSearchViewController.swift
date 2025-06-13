//
//  BreedSearchViewController.swift
//  SherlDog
//
//  Created by 최영락 on 6/10/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class BreedSearchViewController: UIViewController {

    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var allBreeds: [String] = ["골든 리트리버", "래브라도 리트리버", "저먼 셰퍼드", "불독", "비글",
                                       "푸들", "로트와일러", "요크셔 테리어", "닥스훈트", "시베리안 허스키",
                                       "보더 콜리", "복서", "그레이트 데인", "시츄", "보스턴 테리어",
                                       "폼피츠", "치와와", "말티즈", "코기", "진돗개"]
    private var filteredBreeds: [String] = []
    private var isSearching = false

    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let closeButton = UIButton()
    private let searchTextField = UITextField()
    private let emptyImageView = UIImageView()
    private let emptyLabel = UILabel()
    private let noResultsImageView = UIImageView()
    private let noResultsLabel = UILabel()
    private let noResultsDescriptionLabel = UILabel()
    private let addBreedButton = UIButton()
    private let tableView = UITableView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureUI()
        setupUI()
        setupConstraints()
        bindUI()
    }

    // MARK: - Setup Methods
    private func configureUI() {
        titleLabel.text = "견종 선택하기"
        titleLabel.font = .highlight3
        titleLabel.textColor = .textPrimary

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .textPrimary

        searchTextField.placeholder = "검색"
        searchTextField.backgroundColor = .gray50
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.borderColor = UIColor.gray200.cgColor
        searchTextField.layer.cornerRadius = 8
        searchTextField.font = .systemFont(ofSize: 16)
        searchTextField.setLeftPaddingIcon(systemName: "magnifyingglass")
        searchTextField.delegate = self

        emptyImageView.image = UIImage(named: "sherlDog")
        emptyImageView.contentMode = .scaleAspectFit
        emptyImageView.tintColor = .gray300
        emptyImageView.alpha = 1

        emptyLabel.text = "어떤 견종을 찾으시나요?"
        emptyLabel.textColor = .textDisabled
        emptyLabel.font = .body3
        emptyLabel.textAlignment = .center

        noResultsImageView.image = UIImage(named: "noResultDog")
        noResultsImageView.contentMode = .scaleAspectFit
        noResultsImageView.tintColor = .gray200
        noResultsImageView.isHidden = true

        noResultsLabel.text = "검색 결과가 없습니다"
        noResultsLabel.textColor = .textDisabled
        noResultsLabel.font = .body2
        noResultsLabel.textAlignment = .center
        noResultsLabel.isHidden = true

        noResultsDescriptionLabel.text = "찾으시는 견종이 검색결과에 없다면\n직접 견종을 추가해보세요"
        noResultsDescriptionLabel.textColor = .textDisabled
        noResultsDescriptionLabel.font = .alert2
        noResultsDescriptionLabel.textAlignment = .center
        noResultsDescriptionLabel.numberOfLines = 2
        noResultsDescriptionLabel.isHidden = true

        addBreedButton.setTitle("견종 직접 추가", for: .normal)
        addBreedButton.setTitleColor(.keycolorPrimary1, for: .normal)
        addBreedButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        addBreedButton.layer.borderWidth = 1
        addBreedButton.layer.borderColor = UIColor.keycolorPrimary1.cgColor
        addBreedButton.layer.cornerRadius = 8
        addBreedButton.isHidden = true

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .gray200
        tableView.register(BreedTableViewCell.self, forCellReuseIdentifier: "BreedCell")
        tableView.isHidden = true
        tableView.keyboardDismissMode = .onDrag
    }

    private func setupUI() {
        [titleLabel, closeButton, searchTextField, emptyImageView, emptyLabel,
         noResultsImageView, noResultsLabel, noResultsDescriptionLabel, addBreedButton, tableView].forEach {
            view.addSubview($0)
        }
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalToSuperview().inset(20)
        }

        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(20)
            $0.size.equalTo(24)
        }

        searchTextField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(40)
        }

        emptyImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(searchTextField.snp.bottom).offset(150)
            $0.size.equalTo(80)
        }

        emptyLabel.snp.makeConstraints {
            $0.top.equalTo(emptyImageView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(searchTextField.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        noResultsImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(searchTextField.snp.bottom).offset(120)
            $0.size.equalTo(80)
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
    
    // MARK: - Actions
    private func bindUI() {
        closeButton.rx.tap
            .bind { [weak self] in
                self?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
        
        addBreedButton.rx.tap
            .bind { [weak self] in
                guard let self = self,
                      let text = self.searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !text.isEmpty else { return }
                self.allBreeds.append(text)
                print("직접 추가된 견종: \(text)")
                self.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
        
        searchTextField.rx.text.orEmpty
            .subscribe(onNext: { [weak self] query in
                guard let self = self else { return }
                if query.isEmpty {
                    self.showEmptyState()
                } else {
                    self.showSearchResults(for: query)
                }
            })
            .disposed(by: disposeBag)
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
        return 60
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
        icon.tintColor = .textDisabled
        icon.contentMode = .scaleAspectFit
        
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        icon.frame = CGRect(x: 8, y: 8, width: 20, height: 20)
        container.addSubview(icon)
        
        self.leftView = container
        self.leftViewMode = .always
    }
}
