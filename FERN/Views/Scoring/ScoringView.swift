//
//  ScoringView.swift
//  FERN
//
//  Created by Hopp, Dan on 9/13/24.
//

import SwiftUI

extension AnyTransition {
    static var moveAndFade: AnyTransition {
        .asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        )
    }
}

struct ScoringView: View {
    
    @State private var dbh = ""
    @State private var height = ""
    
    @State private var showDBHScore = false
    @State private var showHeightScore = false
    @State private var showSelectMeasurement = false
    
    @State private var isScoringActive = false
    @State private var isSelectMeasuremntActive = false
    
    @State private var selectedLength = "cm"
    let lengths = ["cm", "mm", "ft", "in"]
    
    @FocusState private var sectionIsFocused: Bool

    
    // ARROW NAVIGATION
    // Previous Point
    var previousPoint: some View {
        //        HStack {
        // backward
        Button(action: {
            sectionIsFocused = false
            withAnimation {
                // actions for when scoring is active
                if isScoringActive {
                    if showHeightScore {
                        showHeightScore = false
                        showDBHScore = true
                    }
                }
            }
        }, label: {
            VStack {
                Image(systemName: "arrowshape.backward.fill")
                    .font(.system(size: 50))
            }
        })
    }
    
    // Next Point
    var nextPoint: some View {
        //        HStack {
        // forward
        Button(action:  {
            sectionIsFocused = false
            withAnimation {
                // actions for when scoring is active
                if isScoringActive {
                    if showDBHScore {
                        showHeightScore = true
                        showDBHScore = false
                    }
                }
            }
        }, label: {
            VStack {
                Image(systemName: "arrowshape.forward.fill")
                    .font(.system(size: 50))
            }
        })
    }
    
    // Scoring Button
    var scoringButton: some View {
        Button {
            Task {
                isScoringActive.toggle()
                if isScoringActive {
                    showDBHScore = true
                } else {showDBHScore = false; showHeightScore = false}
            }
        } label: {
            HStack {
                Text("Toggle Scoring")//.font(.system(size:12))
            }
            .frame(minWidth: 0, maxWidth: 150, minHeight: 0, maxHeight: 50)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    // Select measurement unit Button
    var selectMeasurementUnitButton: some View {
        Button {
            Task {
                isSelectMeasuremntActive.toggle()
                if isSelectMeasuremntActive {
                    showSelectMeasurement = true
                } else {showSelectMeasurement = false}
            }
        } label: {
            HStack {
                if isSelectMeasuremntActive {
                    Text("Done")
                } else {
                    Text("Select Unit")
                }
            }
            .frame(minWidth: 0, maxWidth: 150, minHeight: 0, maxHeight: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    // length variable picker
    var lengthVariablePicker: some View {
        Form {
            Section {
                Picker("Strength", selection: $selectedLength) {
                    ForEach(lengths, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
        .navigationTitle("Select unit of measurement")
    }
    
    var body: some View {
        
        Rectangle()
            .fill(.green)
            .frame(width: 300, height: 300)
               
        if showSelectMeasurement {
            lengthVariablePicker
        }
        
        if isScoringActive {
            selectMeasurementUnitButton
        }
        
        HStack {
            // DBH
            if showDBHScore {
                HStack {
                    Text("DBH:").padding().padding()
                    TextField("Enter DBH", text: $dbh).keyboardType(.decimalPad)
                    Text(selectedLength).padding().padding()
                }.transition(.moveAndFade)
            }
            
            // height
            if showHeightScore {
                HStack {
                    Text("Height:").padding().padding()
                    TextField("Enter Height", text: $height).keyboardType(.decimalPad)
                    Text(selectedLength).padding().padding()
                }.transition(.moveAndFade)
            }
        }.focused($sectionIsFocused)
        
        HStack {
            previousPoint.padding(.trailing, 20)
            scoringButton
            nextPoint.padding(.leading, 20)
        }.padding(.bottom, 20)
        
    }
}

