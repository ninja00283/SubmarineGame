using Godot;
using System;
using System.Collections.Generic;
using System.Formats.Asn1;
using System.Linq;
using System.Transactions;

public enum MorseLengths{

	Dot = MorseLengths.Unit * 1,
	Dash = MorseLengths.Unit * 3,
	Space = MorseLengths.Unit * 4,
	End = -1,
	Unit = 1,
}
/*
	distinct spaces aren't necessarily necessary for the game 
	SpaceSameLetter = MorseLengths.Unit * 1,
	SpaceLetter = MorseLengths.Unit * 3,
	SpaceWords = MorseLengths.Unit * 7,
*/

/*
	1. The length of a dot is one unit. 
	2. A dash is three units. 
	3. The space between parts of the same letter is one unit. 
	4. The space between letters is three units. 
	5. The space between words is seven units.
	
	problem #1:
		We need to know the length of one unit:
			first input is considered either a dot or a dash but left undefined until a input of a different length is entered
			then if that secondary input is shorter then it was a dash if it was longer then it was a dot
			a phrase never starts with a space so it has to be either a dot or a dash
		-rejection of the problem as a whole:
			turns out that we don't need variable unit lengths and a hardcoded system works just as well



	end goal:
		we have a list of possible actions in string form
		The player will type out the their desired action in morse
		Each action will be the action itself and multiple numbers, one for angle, one for speed, and a bonus value if necessary
		The system will then match translate the input and compare it and match to that list with a confidence/accuracy value
		the eventual match and accuracy value will be served to the player character to be taken next action request
		
	
*/



public partial class MorseCodeInterpreterNode : Node
{
	//Each raw input will be defined as the frame count since the last input * delta and the duration of the press * delta
	List<(double SinceLast,double Length)> MorseInputRaw = new();
	List<MorseLengths> MorseInputCodes = new();
	double TimeSinceLastInput = 0;
	bool MorseIsPressed = false;



	double UnitLength = 0.1;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		if(MorseInputRaw.Count > 0){
			TimeSinceLastInput+=delta;
		}
		if(!MorseIsPressed && Input.IsActionJustPressed("MorseInput")){
			MorseInputRaw.Add((TimeSinceLastInput,0));
			TimeSinceLastInput = 0;
			MorseIsPressed = true;
		}
		if(MorseIsPressed && Input.IsActionJustReleased("MorseInput")){
			MorseInputRaw[^1] = (MorseInputRaw[^1].SinceLast,TimeSinceLastInput);
			TimeSinceLastInput = 0;
			MorseIsPressed = false;
			MorseInputCodes.Add(MorseCodeInterpreter.InterpretInput(MorseInputRaw,UnitLength));
			GD.Print("SinceLast:" + MorseInputRaw[^1].SinceLast + ", Length:" + MorseInputRaw[^1].Length + ", type: " + MorseInputCodes[^1] + " Current Letter: " + MorseCodeInterpreter.MorseWordToChar(MorseInputCodes));
			if(MorseInputRaw.Count > 6){
				MorseInputRaw = new();
				MorseInputCodes = new();
				GD.Print("cleared");
			}
		}
	}
}

public static class MorseCodeInterpreter{
	static readonly double Fuzziness = 0.1;

	static readonly List<List<MorseLengths>> MorseCodes = new(){
		new(){MorseLengths.Dot, MorseLengths.Dash},                                           // A
		new(){MorseLengths.Dash, MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot},       // B
		new(){MorseLengths.Dash, MorseLengths.Dot, MorseLengths.Dash, MorseLengths.Dot},      // C
		new(){MorseLengths.Dash, MorseLengths.Dot, MorseLengths.Dot},                         // D
		new(){MorseLengths.Dot},                                                              // E
		new(){MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dash, MorseLengths.Dot},       // F
		new(){MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dot},                        // G
		new(){MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot},        // H
		new(){MorseLengths.Dot, MorseLengths.Dot},                                            // I
		new(){MorseLengths.Dot, MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dash},     // J
		new(){MorseLengths.Dash, MorseLengths.Dot, MorseLengths.Dash},                        // K
		new(){MorseLengths.Dot, MorseLengths.Dash, MorseLengths.Dot, MorseLengths.Dot},       // L
		new(){MorseLengths.Dash, MorseLengths.Dash},                                          // M
		new(){MorseLengths.Dash, MorseLengths.Dot},                                           // N
		new(){MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dash},                       // O
		new(){MorseLengths.Dot, MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dot},      // P
		new(){MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dot, MorseLengths.Dash},     // Q
		new(){MorseLengths.Dot, MorseLengths.Dash, MorseLengths.Dot},                         // R
		new(){MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot},                          // S
		new(){MorseLengths.Dash},                                                             // T
		new(){MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dash},                         // U
		new(){MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dash},       // V
		new(){MorseLengths.Dot, MorseLengths.Dash, MorseLengths.Dash},                        // W
		new(){MorseLengths.Dash, MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot},       // X
		new(){MorseLengths.Dash, MorseLengths.Dot, MorseLengths.Dash, MorseLengths.Dash},     // Y
		new(){MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dot, MorseLengths.Dot},      // Z

		new(){MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dash}, // 0
		new(){MorseLengths.Dot, MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dash},  // 1
		new(){MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dash},   // 2
		new(){MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dash, MorseLengths.Dash},    // 3
		new(){MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dash},     // 4
		new(){MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot},      // 5
		new(){MorseLengths.Dash, MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot},     // 6
		new(){MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dot, MorseLengths.Dot, MorseLengths.Dot},    // 7
		new(){MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dot, MorseLengths.Dot},   // 8
		new(){MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dash, MorseLengths.Dot},  // 9


	};

	static readonly char[] MorseCodeReferenceArray = {
		'A',
		'B',
		'C',
		'D',
		'E',
		'F',
		'G',
		'H',
		'I',
		'J',
		'K',
		'L',
		'M',
		'N',
		'O',
		'P',
		'Q',
		'R',
		'S',
		'T',
		'U',
		'V',
		'W',
		'X',
		'Y',
		'Z',
		'1',
		'2',
		'3',
		'4',
		'5',
		'6',
		'7',
		'8',
		'9',
		'0'
	}; 

	public static MorseLengths InterpretInput(List<(double SinceLast,double Length)> morseInputRaw, double UnitLength){
		//morseInputRaw[^1].Length > UnitLength * ((int)MorseLengths.Dot * (1 -Fuzziness)) && 
		if(morseInputRaw[^1].Length < UnitLength * ((int)MorseLengths.Dot * (1 + Fuzziness))){
			return MorseLengths.Dot;
		}else{// if(morseInputRaw[^1].Length > UnitLength * ((int)MorseLengths.Dash * (1 -Fuzziness)) && morseInputRaw[^1].Length < UnitLength * ((int)MorseLengths.Dash * (1 + Fuzziness))){
			return MorseLengths.Dash;
		}//else{return MorseLengths.End;}
	}

	public static (char value, int AccuracyValue) MorseWordToChar(List<MorseLengths> Word){
		List<(List<MorseLengths> MorseCodes, int Accuracy)> Candidates = new();
		(char value, int AccuracyValue) FinalCandidates = new(' ', 0);
		foreach (List<MorseLengths> item in MorseCodes){
			Candidates.Add((item,10 - Math.Abs(item.Count - Word.Count)));
		}
		for (int i = 0; i < Word.Count; i++){
			for (int currentCandidateIndex = 0; currentCandidateIndex < Candidates.Count; currentCandidateIndex++){
				if(i < Candidates[currentCandidateIndex].MorseCodes.Count){
					if(Candidates[currentCandidateIndex].MorseCodes[i] == Word[i]){
						Candidates[currentCandidateIndex] = (Candidates[currentCandidateIndex].MorseCodes, Candidates[currentCandidateIndex].Accuracy + 1);
					}else{
						Candidates[currentCandidateIndex] = (Candidates[currentCandidateIndex].MorseCodes, Candidates[currentCandidateIndex].Accuracy - 1);
					}
				}
			}
		}
		for (int currentCandidateIndexLastPass = 0; currentCandidateIndexLastPass < Candidates.Count; currentCandidateIndexLastPass++){
			if(FinalCandidates.AccuracyValue < Candidates[currentCandidateIndexLastPass].Accuracy){
				FinalCandidates.value = MorseCodeReferenceArray[currentCandidateIndexLastPass];
				FinalCandidates.AccuracyValue = Candidates[currentCandidateIndexLastPass].Accuracy;
			}
		}
		return FinalCandidates;
	}
}
