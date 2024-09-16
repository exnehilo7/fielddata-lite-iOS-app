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
    
    
    // For custom numberpad
    @State var score = ""
    @State private var showScoreTextField = false
    @State private var scoreType = "The score type"
    
    //Numberpad Button
    struct numberpadButton: View {
        var labelAndValue: String
        var width: CGFloat
        var height: CGFloat
        @Binding var score: String
        var isBackspace: Bool
        
        var body: some View {
            Button(action: {
                if isBackspace {
                    if score != "" {
                        score.removeLast()
                    }
                } else {
                    score.append(labelAndValue)
                }
            }, label: {
                if isBackspace {
                    Image(systemName: "arrow.left").bold(false).foregroundColor(.white).font(.system(size:35))
                } else {
                    Text(labelAndValue).font(.system(size:40))
                }
            })
            .frame(width: width, height: height)
            .background(Color(red: 0.5, green: 0.5, blue: 0.5))
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10.0))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 2))
        }
    }
    
    // ARROW NAVIGATION
    // Previous Point
    var previousPoint: some View {
        //        HStack {
        // backward
        Button(action: {
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
                    showScoreTextField = true
                } else {
                    showScoreTextField = false
                    showSelectMeasurement = false
                }
            }
        } label: {
            HStack {
                if isScoringActive {
                    Text("Done")//.font(.system(size:12))
                } else { Text("Score")}
            }
            .frame(minWidth: 0, maxWidth: 150, minHeight: 50, maxHeight: 50)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
//    // Select measurement unit Button
//    var selectMeasurementUnitButton: some View {
//        Button {
//            Task {
//                isSelectMeasuremntActive.toggle()
//                if isSelectMeasuremntActive {
//                    showSelectMeasurement = true
//                } else {showSelectMeasurement = false}
//            }
//        } label: {
//            HStack {
//                if isSelectMeasuremntActive {
//                    Text("Done")
//                } else {
//                    Text("Select Measurement")
//                }
//            }
//            .frame(minWidth: 0, maxWidth: 150, minHeight: 0, maxHeight: 50)
//            .background(Color.blue)
//            .foregroundColor(.white)
//            .cornerRadius(10)
//            .padding(.horizontal)
//        }
//    }
    
    // length type picker
    var lengthTypePicker: some View {
        Form {
            Section {
                Picker("Unit", selection: $selectedLength) {
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
            .frame(minWidth: 300, maxWidth: 300, minHeight: 10, maxHeight: 300)
        
//        if isScoringActive {
//            selectMeasurementUnitButton
//        }
        
        // Score and numberpad
        if showScoreTextField {
            // Score, label, and type
            HStack {
                Text("\(scoreType):").padding().padding()
                Text(score)
                Text(selectedLength).padding().padding().onTapGesture {
                    showSelectMeasurement.toggle()
                }.popover(isPresented: $showSelectMeasurement) { lengthTypePicker }
            }
            // Numberpad
            VStack {
                // 7 - 9
                HStack {
                    numberpadButton(labelAndValue: "7", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "8", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "9", width: 50, height: 50, score: $score, isBackspace: false)
                }
                // 4 - 6
                HStack {
                    numberpadButton(labelAndValue: "4", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "5", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "6", width: 50, height: 50, score: $score, isBackspace: false)
                }
                // 1 - 3
                HStack {
                    numberpadButton(labelAndValue: "1", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "2", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "3", width: 50, height: 50, score: $score, isBackspace: false)
                }
                // ., 0, backspace
                HStack {
                    numberpadButton(labelAndValue: ".", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "0", width: 50, height: 50, score: $score, isBackspace: false)
                    numberpadButton(labelAndValue: "", width: 50, height: 50, score: $score, isBackspace: true)
                }
            }
        }
        
        // DBH
//        if showDBHScore {
//            HStack {
//                Text("DBH:").padding().padding()
//                TextField("Enter DBH", text: $dbh).keyboardType(.decimalPad)
//                Text(selectedLength).padding().padding()
//            }.transition(.moveAndFade)
//        }
//
//        // height
//        if showHeightScore {
//            HStack {
//                Text("Height:").padding().padding()
//                TextField("Enter Height", text: $height).keyboardType(.decimalPad)
//                Text(selectedLength).padding().padding()
//            }.transition(.moveAndFade)
//        }
        
        HStack {
            previousPoint.padding(.trailing, 20)
            scoringButton
            nextPoint.padding(.leading, 20)
        }.padding(.bottom, 20)
        
    }
}
