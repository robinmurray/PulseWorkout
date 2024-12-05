//
//  SwipeButton.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 27/11/2024.
//

import SwiftUI


struct SwipeButton: View {
    

    var swipeText: String
    var perform: () -> Void
    var buttonColor: Color
    var width: CGFloat
    var buttonWidth: CGFloat
    var buttonOffset: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat
    var maxDrag: CGFloat
    
    @State var viewState: CGSize
    @State var triggered: Bool = false
    
    init (swipeText: String,
          perform: @escaping () -> Void,
          buttonColor: Color = Color.red,
          width: CGFloat = 300,
          height: CGFloat = 75) {
        
        self.swipeText = swipeText
        self.perform = perform
        self.buttonColor = buttonColor
        self.width = width
        self.height = height
        self.buttonWidth = height
        self.maxDrag = width - buttonWidth
        self.buttonOffset = -width/2 + buttonWidth/2
        self.cornerRadius = min(buttonWidth / 2, 40)
        self.viewState = CGSize(width: 0, height: height)
        
    }
    
    func showDrag(dragPosition: CGFloat) -> Bool {
        return (dragPosition <= maxDrag) && (dragPosition >= 0)
    }
    
    var body: some View {
        HStack {
            ZStack {

                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.5))


                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0))
                    .overlay {
                        HStack {
                            Text(swipeText)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.background)
                                .padding()
                            Spacer()
                        }
                       
                    }
                    .offset(x: buttonWidth / 2)
                    .frame(width: width - buttonWidth, height: height)

            
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray)
                    .frame(width: buttonWidth + viewState.width,
                           height: height)
                    .offset(x: (viewState.width/2) + buttonOffset)
                    .gesture(
                        DragGesture().onChanged { value in
                            if showDrag(dragPosition: value.translation.width)
                            {
                                viewState = value.translation
                            }

                        }
                            .onEnded { value in
                                withAnimation(.spring()) {
                                    viewState = .zero
                                }
                            }
                    )
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(buttonColor)
                    .frame(width: buttonWidth, height: height)
                    .offset(x: viewState.width  + buttonOffset)
                    .gesture(
                        DragGesture().onChanged { value in
                            if showDrag(dragPosition: value.translation.width)
                            {
                                viewState = value.translation
                            }
                            if (viewState.width > maxDrag * 0.95) &&
                                !triggered {
                                triggered = true
                                perform()
                            }
                        }
                            .onEnded { value in
                                withAnimation(.spring()) {
                                    viewState = .zero
                                }
                                if value.translation.width >= maxDrag {

                                    if !triggered {
                                        triggered = true
                                        perform()
                                    }
                                }
                            }
                    )
                
                Image(systemName: "chevron.forward.circle")
                    .resizable()
                    .frame(width: buttonWidth * 0.7, height: height * 0.7)
                    .offset(x: viewState.width + buttonOffset)
                    .foregroundColor(Color.white)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if showDrag(dragPosition: value.translation.width) {
                                    viewState = value.translation
                                }
                                
                                /*
                                if (value.translation.width <= maxDrag) {
                                    print("viewState : \(viewState)")
                                }
                                */
                                
                                if (viewState.width > maxDrag * 0.95) &&
                                    !triggered {
                                    triggered = true
                                    perform()
                                }
                                
                            }
                            .onEnded { value in
                                withAnimation(.spring()) {
                                    viewState = .zero
                                    }
                                if value.translation.width >= maxDrag {

                                    if !triggered {
                                        triggered = true
                                        perform()
                                    }
                                }
                            }
                    )
            }
        }
        .frame(width: width, height: height, alignment: .center)
        .onAppear(perform: {triggered = false})
    }
}

#Preview {

    
    SwipeButton(swipeText: "Print...",
        perform: {print("Hello World")})
}
