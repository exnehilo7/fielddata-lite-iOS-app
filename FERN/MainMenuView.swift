//
//  MainMenuView.swift
//  FERN
//
//  Created by Hopp, Dan on 2/3/23.
//

import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationStack{
            List {
                NavigationLink {
                   SelectSavedRouteView()
                        .navigationTitle("Load Saved Route")
                } label: {
                    HStack {
                        Image(systemName: "map").bold(false).foregroundColor(.gray)
                        Text("Load Saved Route")
                    }
                }
                NavigationLink {
                    SelectAreaView(phpFile: "menusAndReports.php", columnName: "area_name")
                        .navigationTitle("Select Area")
                } label: {
                    HStack {
                        Image(systemName: "rectangle.dashed").bold(false).foregroundColor(.gray)
                        Text("Select Area")
                    }
                }
                NavigationLink {
                    SelectAreaView(phpFile: "menusAndReports.php",  columnName: "plot_name")
                        .navigationTitle("Select Plot")
                } label: {
                    HStack {
                        Image(systemName: "rectangle.center.inset.fill").bold(false).foregroundColor(.gray)
                        Text("Select Plot")
                    }
                }
                NavigationLink {
                    SelectReportView(phpFile: "menusAndReports.php")
                        .navigationTitle("Select Report")
                } label: {
                    HStack {
                        Image(systemName: "newspaper").bold(false).foregroundColor(.gray)
                        Text("Reports")
                    }
                }
                NavigationLink {
                    SelectNotesView(phpFile: "notes.php")
                        .navigationTitle("Notes")
                } label: {
                    HStack {
                        Image(systemName: "pencil.line").bold(false).foregroundColor(.gray)
                        Text("Notes")
                    }
                }
//                NavigationLink {
//                    NMEADataView()
//                        .navigationTitle("GPS Stream")
//                } label: {
//                    HStack {
//                        Image(systemName: "antenna.radiowaves.left.and.right").bold(false).foregroundColor(.gray)
//                        Text("GPS Stream")
//                    }
//                }
                NavigationLink {
                    CameraView()
                        .navigationTitle("Camera Test")
                } label: {
                    HStack {
                        Image(systemName: "camera").bold(false).foregroundColor(.gray)
                        Text("Camera Test")
                    }
                }
                }.bold()
            }
        }
    }

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
