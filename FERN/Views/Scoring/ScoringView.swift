//
//  ScoringView.swift
//  FERN
//
//  Created by Hopp, Dan on 9/13/24.
//
// Intended to be called/created within other views

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
    
    // When adding another score type, REMEMBER TO ADD TO THE THREE ARRAYS BELOW
    @State private var scoresToSave = ["", ""]
    @State private var unitsToSave = ["cm", "cm"]
    let measurementLables = ["DBH", "Height"]
    @State private var currMeasureLabel = 0
    
    @State private var showSelectMeasurement = false
    
    @State var isScoringActive = false
    
    @State private var selectedUnit = "cm"
    let units = ["cm", "mm", "ft", "in"]
    
    
    // For custom numberpad
    @State var score = ""
    @State private var showScoreTextField = false
    @State private var scoreType = "The score type"
    
    // Scoring measurement type navigation
    func cycleScoringTypes(forward: Bool) {
           
       let count = measurementLables.count

       if forward {
           // Is end reached?
           if count == currMeasureLabel + 1 {
               // do nothing
           } else {
               exchangeScoreValues(dir: 1)
           }
           
       } else {
           // Is start reached?
           if currMeasureLabel == 0 {
               // do nothing
           } else {
               exchangeScoreValues(dir: -1)
           }
       }
    }
    private func exchangeScoreValues(dir: Int) {
       // Assign score to current type's variable
       scoresToSave[currMeasureLabel] = score
       unitsToSave[currMeasureLabel] = selectedUnit
       
       // Move to the next score
       currMeasureLabel = currMeasureLabel + dir
       scoreType = measurementLables[currMeasureLabel]
       score = scoresToSave[currMeasureLabel]
       selectedUnit = unitsToSave[currMeasureLabel]
    }
    
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
        // backward
        Button(action: {
            withAnimation {
                // actions for when scoring is active
                if isScoringActive {
                    cycleScoringTypes(forward: false)
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
        // forward
        Button(action:  {
            withAnimation {
                // actions for when scoring is active
                   if isScoringActive {
                       cycleScoringTypes(forward: true)
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
                print("Toggling scoring!")
                isScoringActive.toggle()
                if isScoringActive {
                    scoreType = measurementLables[currMeasureLabel]
                    score = scoresToSave[currMeasureLabel]
                    selectedUnit = unitsToSave[currMeasureLabel]
                    showScoreTextField = true
                } else {
                    // Assign score to current type's variable, write vars to CSV, reset vars (except score type units)
                    
                    // Hide
                    showScoreTextField = false
                }
            }
        } label: {
            HStack {
                if isScoringActive {
                    Text("Done")//.font(.system(size:12))
                } else { Text("Score")}
            }
            .frame(minWidth: 0, maxWidth: 150, minHeight: 0, maxHeight: 50)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    // length type picker
    var lengthTypePicker: some View {
        Form {
            
            Section {
                HStack {
                    Image(systemName: "chevron.compact.down").bold(false).foregroundColor(.white)
                    Text("Swipe down when finished").bold(false)
                }
                Picker("Unit", selection: $selectedUnit) {
                    ForEach(units, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
        .navigationTitle("Select unit of measurement")
    }
    
    var body: some View {
        
//        Rectangle()
//            .fill(.green)
//            .frame(minWidth: 300, maxWidth: 300, minHeight: 10, maxHeight: 300)
        
        // Score and numberpad
        if showScoreTextField {
            // Score, label, and type
            HStack {
                Text("\(scoreType):").padding().padding()
                Text(score)
                Button {
                    showSelectMeasurement.toggle()
                } label: {
                    HStack {
                        Text("\(selectedUnit)")
                        Image(systemName: "arrow.up.and.down").bold(false).foregroundColor(.white)//.font(.system(size:35))//arrow.up.and.down
                    }
                    .frame(minWidth: 20, maxWidth: 60, minHeight: 20, maxHeight: 23)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .padding(.horizontal)
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
                }.padding(.bottom, 20)
            }
        }
        
//        HStack {
//            previousPoint.padding(.trailing, 20)
//            scoringButton
//            nextPoint.padding(.leading, 20)
//        }.padding(.bottom, 20)
        
    }
}
