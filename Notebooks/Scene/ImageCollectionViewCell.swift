//
//  ImageCollectionViewCell.swift
//  Notebooks
//
//  Created by Franco Paredes on 15/02/21.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageNote: UIImageView?

    override func awakeFromNib() {
        super.awakeFromNib()
        imageNote?.layer.cornerRadius = 4.0
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageNote?.image = nil
    }

    func configureViews(image: UIImage?) {
        imageNote?.image = image
    }
}
