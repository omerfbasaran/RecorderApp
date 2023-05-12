//
//  ViewController.swift
//  RapsodoApp
//
//  Created by Ömer Faruk Başaran on 29.04.2023.
//

import UIKit
import RealmSwift
import Reachability
import AVFoundation

class ViewController: UIViewController, UICollectionViewDelegate {
    
    
    var playerObjects = [Player](){
    didSet {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            print("reloadData")
        }
    }
}
    
    let cellIdentifier = "ShotsCell"
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var selectedShotId = ""
    var indexSection = 0
    var indexRow = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                print("Mikrofon izni verildi")
            } else {
                print("Mikrofon izni verilmedi")
            }
        }
        
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                print("Kamera izni verildi")
            } else {
                print("Kamera izni verilmedi")
            }
        }
        // Do any additional setup after loading the view.
        if hasInternetConnection() {
            fetchDataFromAPI()
            print("apiden")
        } else {
            fetchDataFromRealm()
            print("realmden")
        }
        let section = getPlayerSection()
        let layout = UICollectionViewCompositionalLayout(section: section!)

        collectionView?.translatesAutoresizingMaskIntoConstraints = false
        collectionView?.backgroundColor = .black
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView.collectionViewLayout = layout
        
        collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //fetchDataFromRealm()
        collectionView.reloadData()
        print("viewwillappear")

    }
    private func getPlayerSection() -> NSCollectionLayoutSection? {
        //create item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0)
        
        //create group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.3), heightDimension: .fractionalHeight(0.22))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        //create section
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0)
        

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
        let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .topLeading)
        headerSupplementary.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: -20, trailing: 0)
        section.boundarySupplementaryItems = [headerSupplementary]
        
        return section
    }
    func fetchDataFromAPI() {
        guard let url = URL(string: "https://interview-2dlcobr5jq-ue.a.run.app/shots") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self?.fetchDataFromRealm()
                return
            }
            
            guard let data = data else {
                print("Error: Invalid data")
                self?.fetchDataFromRealm()
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let players = try decoder.decode([Player].self, from: data)
                self?.playerObjects = players
                self?.saveToRealm(playerObjects: players)
                //print(players)
                
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                self?.fetchDataFromRealm()
            }
        }.resume()
    }
    func fetchDataFromRealm() {
        DispatchQueue.main.async {
            
            let players = realm.objects(Player.self)
            self.playerObjects = Array(players)
            
            print("readed")
            self.collectionView.reloadData()
        }
    }
    func saveToRealm(playerObjects: [Player]) {
        DispatchQueue.main.async {
            let realm = try! Realm()
            
            try! realm.write {
                for playerObject in playerObjects {
                    for shot in playerObject.shots {
                        let existingShot = realm.object(ofType: Shot.self, forPrimaryKey: shot._id)
                        
                        if let existingShot = existingShot {
                            shot.videoURL = existingShot.videoURL
                        }
                    }
                    
                    realm.add(playerObject, update: .modified)
                    print("added")
                }
            }
        }
    }
    func hasInternetConnection() -> Bool {
        let reachability = try! Reachability()
        return reachability.connection != .unavailable
    }

}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return playerObjects[section].shots.count
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return playerObjects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        cell.backgroundColor = .lightGray
        
        let image = UIImageView(frame: CGRect(x: 0, y: 0, width: cell.frame.size.width, height: cell.frame.height))
        image.contentMode = .scaleAspectFit
        if playerObjects[indexPath.section].shots[indexPath.row].videoURL == nil {
            image.image = UIImage(named: "gray-play")
        } else {
            image.image = UIImage(named: "red-play")
        }
        cell.contentView.addSubview(image)
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath) as! HeaderView
            headerView.titleLabel.text = "\(playerObjects[indexPath.section].fullName)"
                return headerView
            }
            fatalError("Unexpected element kind")
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        indexSection = indexPath.section
        indexRow = indexPath.row
        print("Section: \(indexSection)")
        print("Row: \(indexRow)")
        selectedShotId = playerObjects[indexPath.section].shots[indexPath.row]._id
        if playerObjects[indexPath.section].shots[indexPath.row].videoURL == nil {
            performSegue(withIdentifier: "toRecordScreenSegue", sender: nil)
            print("record ekranı segue")
        } else {
            performSegue(withIdentifier: "toPlayerScreenSegue", sender: nil)
            print("player ekranı segue")
        }
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toRecordScreenSegue"{
            if let viewController = segue.destination as? CamViewController{
                viewController.indexSection = indexSection
                viewController.indexRow = indexRow
                viewController.shotId = selectedShotId
                viewController.playerObjects = Array(realm.objects(Player.self))
                
            }
        } else if segue.identifier == "toPlayerScreenSegue" {
            if let viewController = segue.destination as? VideoPlayerViewController{
                viewController.videoURL = URL(string: playerObjects[indexSection].shots[indexRow].videoURL!)
                //print(viewController.videoURL)
            }
        }
    }
    
}
