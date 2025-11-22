//
//  ReportViewController.swift
//  SherlDog
//
//  Created by Jin Lee on 11/13/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import FirebaseAuth

class ReportViewController : UIViewController {
    
    enum Target {
        case post(collection: FirestoreCollection, documentId: String, postUserId: String)
        case user(userId: String)
    }
    
    private let target: Target
    private let disposeBag = DisposeBag()
    
    private let reportViewLabel = UILabel()
    private let closeButton = UIButton()
    
    private let reportReasonButton = UIButton()
    
    private let contentTextView = UITextView()
    private let textViewPlaceholderLabel = UILabel()
    private let reportConfirmButton = ButtonFactory.makeButton(
        type: .main,
        title: SDLiteral.ReportViewController.reportConfirmButtonTitle)
    private let loadingIndicator = CustomLoadingIndicator()
    
    private var selectedReason: String? {
           didSet { updateConfirmEnabled() }
       }
    
    init(target: Target) {
            self.target = target
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bind()
        setupUI()
        configureUI()
    }
    
    func bind() {
           closeButton.rx.tap
               .bind { [weak self] in self?.dismiss(animated: true) }
               .disposed(by: disposeBag)
           
           reportReasonButton.rx.tap
               .bind { [weak self] in
                   self?.presentReasonBottomSheet()
               }
               .disposed(by: disposeBag)
           
           contentTextView.rx.text.orEmpty
               .subscribe(onNext: { [weak self] text in
                   guard let self else { return }
                   let isEmpty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                   self.textViewPlaceholderLabel.isHidden = !isEmpty
                   self.updateConfirmEnabled()
               })
               .disposed(by: disposeBag)
           
           reportConfirmButton.rx.tap
               .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
               .bind { [weak self] in
                   self?.submitReport()
               }
               .disposed(by: disposeBag)
       }
       
       func presentReasonBottomSheet() {
           let sheet = ReportReasonBottomSheetViewController()
           
           sheet.selectedReason
               .observe(on: MainScheduler.instance)
               .subscribe(onNext: { [weak self] reason in
                   guard let self else { return }
                   
                   let text = reason.rawValue
                   
                   self.selectedReason = text
                   self.reportReasonButton.setTitle(text, for: .normal)
               })
               .disposed(by: disposeBag)
           
           if let sp = sheet.sheetPresentationController {
               sp.detents = [.medium()]
               sp.prefersGrabberVisible = true
           }
           present(sheet, animated: true)
       }
       
       func updateConfirmEnabled() {
           let hasReason = selectedReason != nil
           let hasContent = !(contentTextView.text ?? "")
               .trimmingCharacters(in: .whitespacesAndNewlines)
               .isEmpty
           
           reportConfirmButton.isEnabled = hasReason && hasContent
       }
       
       func submitReport() {
           guard let reason = selectedReason else { return }
           let detail = contentTextView.text ?? ""
           let reporter = Auth.auth().currentUser?.uid ?? "anonymous"

           let (collection, documentId): (FirestoreCollection, String) = {
               switch target {
               case let .post(collection, docId, _):
                   return (collection, docId)
               case let .user(userId):
                   return (.humanProfile, userId)
               }
           }()
           
           let reportData = BlockModel(
               collection: collection.rawValue,
               documentId: documentId
           )
        
           FirestoreManager.shared.createDocument(
               collection: .blockLog,
               data: reportData,
               documentId: documentId
           )
           .subscribe(onCompleted: { [weak self] in
               guard let self else { return }
               let alert = CustomAlertViewController(
                   message: "신고가 접수되었습니다.",
                   buttons: [
                       .init(title: SDLiteral.AlertMessage.confirm, action: { [weak self] in
                           self?.dismiss(animated: true)
                       })
                   ]
               )
               self.present(alert, animated: true)
           }, onError: { error in
               print("신고 실패:", error)
           })
           .disposed(by: disposeBag)
       }
    
    private func presentReasonSheet() {
        let sheet = ReportReasonBottomSheetViewController()
        sheet.modalPresentationStyle = .overFullScreen
        
        sheet.selectedReason
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] reason in
                guard let self else { return }
                let text = reason.rawValue
                
                self.selectedReason = text
                self.reportReasonButton.setTitle(reason.rawValue, for: .normal)
                self.reportReasonButton.setTitleColor(.textPrimary, for: .normal)

            })
            .disposed(by: disposeBag)
        present(sheet, animated: false)
    }
    
    private func setupUI() {
        view.backgroundColor = .keycolorBackground
        
        view.addSubviews([
            reportViewLabel,
            closeButton,
            reportReasonButton,
            contentTextView,
            textViewPlaceholderLabel,
            reportConfirmButton,
            loadingIndicator
        ])
        
        reportViewLabel.text = SDLiteral.ReportViewController.reportViewLabelTitle
        reportViewLabel.font = .highlight3
        reportViewLabel.textColor = .textPrimary
        
        closeButton.setImage(UIImage(systemName: SDLiteral.ReportViewController.closeButtonImageTitle), for: .normal)
        closeButton.tintColor = .textPrimary
        
        reportReasonButton.setTitle(SDLiteral.ReportViewController.reportReasonButtonTitle, for: .normal)
        reportReasonButton.setTitleColor(.textSecondary, for: .normal)
        reportReasonButton.titleLabel?.font = .body3
        reportReasonButton.contentHorizontalAlignment = .left
        reportReasonButton.backgroundColor = .gray50
        reportReasonButton.layer.cornerRadius = 6
        reportReasonButton.contentEdgeInsets = .init(top: 0, left: 12, bottom: 0, right: 12)
        
        contentTextView.font = .body3
        contentTextView.backgroundColor = .gray50
        contentTextView.layer.cornerRadius = 6
        contentTextView.textContainerInset = .init(top: 12, left: 4, bottom: 12, right: 4)
        contentTextView.textColor = .textPrimary
        
        textViewPlaceholderLabel.text = SDLiteral.ReportViewController.textViewPlaceholderLabel
        textViewPlaceholderLabel.font = .body6
        textViewPlaceholderLabel.textColor = .gray500
        textViewPlaceholderLabel.numberOfLines = 0
        
        self.reportConfirmButton.isEnabled = false
    }
    
    private func configureUI() {
        reportViewLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalToSuperview().inset(20)
        }
        
        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(reportViewLabel)
            $0.trailing.equalToSuperview().inset(20)
            $0.size.equalTo(24)
        }
        
        reportReasonButton.snp.makeConstraints {
            $0.top.equalTo(reportViewLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        
        contentTextView.snp.makeConstraints {
            $0.top.equalTo(reportReasonButton.snp.bottom).offset(16)
            $0.leading.trailing.equalTo(reportReasonButton)
            $0.bottom.equalTo(reportConfirmButton.snp.top).offset(-16)
        }
        
        textViewPlaceholderLabel.snp.makeConstraints {
            $0.top.equalTo(contentTextView).offset(16)
            $0.leading.equalTo(contentTextView).offset(8)
            $0.trailing.lessThanOrEqualTo(contentTextView).inset(8)
        }
        
        reportConfirmButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        loadingIndicator.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
